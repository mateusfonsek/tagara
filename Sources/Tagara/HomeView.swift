import Charts
import SwiftUI
import TagaraCore

struct HomeView: View {
    @Environment(AppController.self) private var controller
    let showHistory: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if controller.needsSetup { SetupCard() }
                stats
                ActivityChart(days: controller.stats.lastDays(14))
                HStack(alignment: .top, spacing: 16) {
                    LastDictationCard(showHistory: showHistory)
                    TryCard()
                }
            }
            .padding(28)
            .frame(maxWidth: 820, alignment: .leading)
        }
        .navigationTitle("Início")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting).font(.largeTitle.weight(.bold))
            HStack(spacing: 6) {
                Text("Segura")
                Keycap(symbol: "⌥", label: "direito")
                Text("e fala. Quando soltar, o texto aparece onde estiver o cursor.")
            }
            .foregroundStyle(.secondary)
            if controller.handsFreeEnabled {
                Text("Para falar sem segurar, toque duas vezes no ⌥. Um toque termina.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let period = hour < 12 ? "Bom dia" : hour < 18 ? "Boa tarde" : "Boa noite"
        let name = NSFullUserName().split(separator: " ").first.map(String.init)
        return name.map { "\(period), \($0)." } ?? "\(period)."
    }

    private var stats: some View {
        HStack(alignment: .top, spacing: 16) {
            StatCard(value: controller.stats.wordsToday().formatted(), label: "palavras hoje", symbol: "text.bubble")
            StatCard(value: controller.stats.totalWords.formatted(), label: "palavras no total", symbol: "character.textbox")
            StatCard(value: saved, label: "economizados", symbol: "clock")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var saved: String {
        let minutes = Int(controller.stats.secondsSaved / 60)
        return minutes < 60 ? "\(minutes) min" : "\((Double(minutes) / 60).formatted(.number.precision(.fractionLength(1)))) h"
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol).foregroundStyle(Brand.violeta)
                Text(value)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(label).font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct ActivityChart: View {
    let days: [UsageStats.Day]

    private func label(_ date: Date) -> String {
        Calendar.current.isDateInToday(date) ? "hoje" : date.formatted(.dateTime.day())
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Últimos 14 dias").font(.headline)
                    Spacer()
                    Text("\(days.map(\.words).reduce(0, +).formatted()) palavras")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Chart(days, id: \.date) { day in
                    BarMark(x: .value("Dia", label(day.date)), y: .value("Palavras", day.words))
                        .foregroundStyle(Calendar.current.isDateInToday(day.date) ? Brand.violeta : Brand.violeta.opacity(0.45))
                        .clipShape(.rect(cornerRadius: 4))
                }
                .chartXAxis { AxisMarks { AxisValueLabel() } }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 140)
            }
        }
    }
}

private struct LastDictationCard: View {
    @Environment(AppController.self) private var controller
    let showHistory: () -> Void
    @State private var copied = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Último ditado").font(.headline)
                if let text = controller.lastTranscript ?? controller.history.entries.first?.text {
                    Text(text)
                        .lineLimit(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    HStack {
                        Button(copied ? "Copiado" : "Copiar", systemImage: copied ? "checkmark" : "doc.on.doc") {
                            controller.copy(text)
                            copied = true
                            Task {
                                try? await Task.sleep(for: .seconds(1.5))
                                copied = false
                            }
                        }
                        Button("Ver histórico", action: showHistory).buttonStyle(.link).foregroundStyle(Brand.violeta)
                    }
                } else {
                    Text("Nada por aqui ainda. Segura ⌥ e manda ver.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                }
            }
        }
    }
}

private struct TryCard: View {
    @State private var text = ""
    /// Stays unfocused on open, so the window doesn't scroll down to this field.
    @FocusState private var focused: Bool

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Experimenta").font(.headline)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($focused)
                        .scrollContentBackground(.hidden)
                        .frame(height: 96)
                    if text.isEmpty {
                        Text("Clica aqui, segura ⌥ direito e fala…")
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .padding(8)
                .background(.background, in: .rect(cornerRadius: 8))
            }
        }
        .defaultFocus($focused, false)
    }
}

private struct SetupCard: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Antes de começar").font(.headline)
                SetupRow(title: "Microfone", detail: "Para ouvir enquanto você segura a tecla.", done: controller.hasMicrophone) {
                    Button("Permitir") { Task { await controller.requestMicrophone() } }
                }
                SetupRow(title: "Acessibilidade", detail: "Para notar a tecla e escrever onde está o cursor.", done: controller.hasAccessibility) {
                    Button("Abrir ajustes") { controller.requestAccessibility() }
                }
                ModelSetupRow()
            }
        }
    }
}

struct SetupRow<Action: View>: View {
    let title: String
    let detail: String
    let done: Bool
    @ViewBuilder let action: Action

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(done ? Color.green : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.medium)
                Text(detail).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            if !done { action.buttonStyle(.borderedProminent) }
        }
    }
}

struct ModelSetupRow: View {
    @Environment(AppController.self) private var controller

    var body: some View {
        let models = controller.models
        SetupRow(title: "Modelo de voz", detail: detail(models.status), done: models.isDownloaded) {
            if case .downloading(let fraction) = models.status {
                ProgressView(value: fraction).frame(width: 90)
            } else {
                Button("Baixar") { Task { await models.download() } }
            }
        }
    }

    private func detail(_ status: ModelManager.Status) -> String {
        switch status {
        case .downloading(let f): "Baixando… \(Int(f * 100))%"
        case .failed(let message): message
        default: "Parakeet Ultra, cerca de 630 MB, baixado uma vez."
        }
    }
}
