import Foundation
import CoreData

@objc(FocusSession)
public class FocusSession: NSManagedObject {
}

extension FocusSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusSession> {
        return NSFetchRequest<FocusSession>(entityName: "FocusSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var start: Date?
    @NSManaged public var end: Date?
    @NSManaged public var durationSeconds: Int32
    @NSManaged public var note: String?
}
