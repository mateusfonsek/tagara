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

            Section("Ditado") {
                LabeledContent("Tecla para falar") { Keycap(symbol: "⌥", label: "direito") }
                LabeledContent("Modelo de voz") {
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
