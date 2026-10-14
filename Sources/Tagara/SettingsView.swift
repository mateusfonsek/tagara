import SwiftUI

struct SettingsView: View {
    @Environment(AppController.self) private var controller
    @State private var confirmClear = false

    var body: some View {
        @Bindable var controller = controller
        @Bindable var models = controller.models
        Form {
            Section("Geral") {
                Toggle("Abrir ao iniciar o Mac", isOn: Binding(
                    get: { controller.launchAtLogin },
                    set: { controller.setLaunchAtLogin($0) }))
                Toggle("Sons ao começar e terminar", isOn: $controller.soundsEnabled)
            }

            MicrophoneSection()

            Section {
                LabeledContent("Tecla para falar") { Keycap(symbol: "⌥", label: "direito") }
                Toggle("Toque duplo no ⌥ trava a gravação", isOn: $controller.handsFreeEnabled)
            } header: {
                Text("Tecla")
            } footer: {
                Text("Segure para falar e solte para escrever. Com o toque duplo, você pode soltar a tecla: um toque no ⌥ termina e Esc cancela.")
            }

            Section("Modelo de voz") {
                LabeledContent("Modelo") {
                    Text("Parakeet Ultra, \(modelState)").foregroundStyle(.secondary)
                }
                Picker("Liberar memória do modelo após", selection: $models.unloadAfterMinutes) {
                    Text("5 minutos").tag(5)
                    Text("10 minutos").tag(10)
                    Text("30 minutos").tag(30)
                    Text("Nunca").tag(0)
                }
            }

            Section {
                Toggle("Guardar histórico dos ditados", isOn: $controller.historyEnabled)
                Button("Apagar histórico…", role: .destructive) { confirmClear = true }
                    .disabled(controller.history.entries.isEmpty)
            } header: {
                Text("Privacidade")
            } footer: {
                Text("Tudo roda neste Mac. Nenhum áudio ou texto sai daqui; o histórico guarda só o texto dos últimos 50 ditados.")
            }

            Section("Permissões") {
                SetupRow(title: "Microfone", detail: "Ouve só enquanto você segura a tecla.", done: controller.hasMicrophone) {
                    Button("Permitir") { Task { await controller.requestMicrophone() } }
                }
                SetupRow(title: "Acessibilidade", detail: "Nota a tecla e escreve onde está o cursor.", done: controller.hasAccessibility) {
                    Button("Abrir ajustes") { controller.requestAccessibility() }
                }
                if !controller.models.isDownloaded { ModelSetupRow() }
            }

            UpdatesSection()
        }
        .formStyle(.grouped)
        .navigationTitle("Ajustes")
        .confirmationDialog("Apagar todo o histórico?", isPresented: $confirmClear) {
            Button("Apagar", role: .destructive) { controller.clearHistory() }
        } message: {
            Text("Os ditados saem deste Mac e não dá para desfazer.")
        }
    }

    private var modelState: String {
        switch controller.models.status {
        case .loaded: "na memória"
        case .loading: "carregando…"
        case .unloaded: "em repouso"
        case .downloading: "baixando…"
        case .notDownloaded: "não baixado"
        case .failed: "com erro"
        }
    }
}

private struct MicrophoneSection: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        Section {
            MicrophonePicker()
        } header: {
            Text("Microfone")
        } footer: {
            Text("Se o microfone escolhido estiver desconectado, o Tagara usa o padrão do sistema. Fones Bluetooth gravam com qualidade de telefone; o microfone do Mac costuma transcrever melhor.")
        }
    }
}

/// The microphone choice, shared by Settings and the menu bar.
struct MicrophonePicker: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        Picker("Microfone", selection: Binding(
            get: { controller.microphoneUID },
            set: { controller.chooseMicrophone(uid: $0) })) {
            Text("Padrão do sistema").tag(String?.none)
            ForEach(controller.microphoneOptions) { option in
                Text(option.isConnected ? option.name : "\(option.name) (desconectado)").tag(Optional(option.uid))
            }
        }
    }
}

private struct UpdatesSection: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        @Bindable var updater = controller.updater
        Section {
            LabeledContent("Versão", value: updater.currentText)
            if updater.status == .development {
                Text("Build de desenvolvimento: não é atualizado pela release.")
                    .foregroundStyle(.secondary)
            } else {
                Toggle("Procurar atualizações automaticamente", isOn: $updater.autoCheck)
                HStack {
                    Text(statusText).foregroundStyle(.secondary)
                    Spacer()
                    if let version = updater.availableVersion {
                        Button("Atualizar para \(version)") { updater.install() }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("Procurar agora") { Task { await updater.check() } }
                            .disabled(updater.status == .checking || updater.status == .installing)
                    }
                }
            }
        } header: {
            Text("Atualizações")
        } footer: {
            Text("A verificação consulta as releases do Tagara no GitHub. Nenhum dado seu é enviado.")
        }
    }

    private var statusText: String {
        switch controller.updater.status {
        case .idle: "Ainda não verificado"
        case .checking: "Procurando…"
        case .upToDate: "Você está na versão mais recente"
        case .available(let version): "Versão \(version) disponível"
        case .installing: "Atualizando… o Tagara vai reabrir"
        case .failed(let message): message
        case .development: ""
        }
    }
}
