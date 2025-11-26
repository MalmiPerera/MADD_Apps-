import Foundation
import CoreData
import Combine

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []

    // Fetch latest entries sorted by date desc
    func fetch(context: NSManagedObjectContext) {
        guard entityExists("JournalEntry", in: context) else {
            print("[JournalVM] fetch: entity 'JournalEntry' does not exist in model")
            entries = []
            return
        }
        let req: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        do {
            entries = try context.fetch(req)
            print("[JournalVM] fetch: fetched \(entries.count) entries")
        } catch {
            print("[JournalVM] fetch error: \(error)")
            entries = []
        }
    }

    // Add new entry and compute sentiment score
    func addEntry(title: String, text: String, context: NSManagedObjectContext) {
        guard entityExists("JournalEntry", in: context) else {
            print("[JournalVM] addEntry: entity 'JournalEntry' does not exist in model")
            return
        }
        let e = JournalEntry(context: context)
        e.id = UUID()
        e.date = Date()
        e.title = title
        e.text = text
        e.sentimentScore = SentimentAnalyzer.shared.score(for: text)
        do {
            try context.save()
            print("[JournalVM] addEntry: saved entry with title='\(title)', score=\(e.sentimentScore)")
        } catch {
            print("[JournalVM] save error: \(error)")
        }
        fetch(context: context)
    }

    // Delete and refresh
    func delete(_ entry: JournalEntry, context: NSManagedObjectContext) {
        guard entityExists("JournalEntry", in: context) else {
            print("[JournalVM] delete: entity 'JournalEntry' does not exist in model")
            return
        }
        context.delete(entry)
        do {
            try context.save()
            print("[JournalVM] delete: deleted entry")
        } catch {
            print("[JournalVM] delete error: \(error)")
        }
        fetch(context: context)
    }

    private func entityExists(_ name: String, in context: NSManagedObjectContext) -> Bool {
        context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[name] != nil
    }
}
