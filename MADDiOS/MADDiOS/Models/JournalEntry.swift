import Foundation
import CoreData

@objc(JournalEntry)
public class JournalEntry: NSManagedObject {
}

extension JournalEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntry> {
        return NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var title: String?
    @NSManaged public var text: String?
    @NSManaged public var sentimentScore: Double
}
