import SwiftUI
import TagaraCore

struct HistoryView: View {
    @Environment(AppController.self) private var controller
    @State private var search = ""
    @State private var confirmClear = false

    var body: some View {
        Group {
            if controller.history.entries.isEmpty {
                ContentUnavailableView(
                    "Nada por aqui ainda", systemImage: "waveform",
                    description: Text(controller.historyEnabled
                        ? "Segura \(controller.triggerKey.name) e manda ver. Seus ditados aparecem aqui."
                        : "O histórico está desligado nos Ajustes."))
            } else if groups.isEmpty {
                ContentUnavailableView.search(text: search)
            } else {
                List {
                    ForEach(groups, id: \.title) { group in
                        Section(group.title) {
                            ForEach(group.entries) { HistoryRow(entry: $0) }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Histórico")
        .searchable(text: $search, prompt: "Buscar nos ditados")
        .toolbar {
            Button("Apagar tudo", systemImage: "trash") { confirmClear = true }
                .disabled(controller.history.entries.isEmpty)
        }
        .confirmationDialog("Apagar todo o histórico?", isPresented: $confirmClear) {
            Button("Apagar", role: .destructive) { controller.clearHistory() }
        } message: {
            Text("Os ditados saem deste Mac e não dá para desfazer.")
        }
    }

    private struct DayGroup {
        let title: String
        let entries: [DictationHistory.Entry]
    }

    private var groups: [DayGroup] {
        let calendar = Calendar.current
        let matching = controller.history.entries.filter {
            search.isEmpty || $0.text.localizedCaseInsensitiveContains(search) || ($0.app ?? "").localizedCaseInsensitiveContains(search)
        }
        let byDay = Dictionary(grouping: matching) { calendar.startOfDay(for: $0.date) }
        return byDay.keys.sorted(by: >).map { day in
            let title = calendar.isDateInToday(day) ? "Hoje"
                : calendar.isDateInYesterday(day) ? "Ontem"
                : day.formatted(.dateTime.weekday(.wide).day().month(.wide))
            return DayGroup(title: title, entries: byDay[day]!.sorted { $0.date > $1.date })
        }
    }
}

private struct HistoryRow: View {
    @Environment(AppController.self) private var controller
    let entry: DictationHistory.Entry
    @State private var hovering = false
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .lineLimit(3)
                    .textSelection(.enabled)
                Text([entry.app, entry.date.formatted(date: .omitted, time: .shortened)].compactMap { $0 }.joined(separator: " · "))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                Button(copied ? "Copiado" : "Copiar", systemImage: copied ? "checkmark" : "doc.on.doc", action: copy)
                Button("Apagar", systemImage: "trash") { controller.removeHistoryEntry(entry.id) }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .opacity(hovering || copied ? 1 : 0)
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
        .onHover { hovering = $0 }
        .onTapGesture(count: 2, perform: copy)
        .contextMenu {
            Button("Copiar", systemImage: "doc.on.doc", action: copy)
            Button("Apagar", systemImage: "trash", role: .destructive) { controller.removeHistoryEntry(entry.id) }
        }
    }

    private func copy() {
        controller.copy(entry.text)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            copied = false
        }
    }
}
