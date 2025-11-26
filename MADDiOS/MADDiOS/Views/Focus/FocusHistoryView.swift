import SwiftUI
import CoreData

struct FocusHistoryView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var sessions: [FocusSession] = []

    var body: some View {
        List {
            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Text("No sessions yet").font(.headline)
                    Text("Start a focus session to build your streak.").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
            } else {
                ForEach(sessions, id: \.objectID) { s in
                    GlassCard {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text((s.end ?? s.start ?? Date()), style: .date)
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text(durationString(seconds: Int(s.durationSeconds)))
                                    .font(.headline)
                                if let note = s.note, !note.isEmpty {
                                    Text(note).font(.subheadline).foregroundStyle(.primary)
                                }
                            }
                            Spacer()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Focus History")
        .onAppear(perform: fetch)
        .refreshable { fetch() }
    }

    private func fetch() {
        let req: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "end", ascending: false)]
        do { sessions = try context.fetch(req) } catch { sessions = [] }
    }

    private func durationString(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%02dh %02dm %02ds", h, m, s) }
        return String(format: "%02dm %02ds", m, s)
    }
}

#Preview {
    NavigationStack { FocusHistoryView() }
}
