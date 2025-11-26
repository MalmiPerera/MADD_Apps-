import Foundation
import CoreData

@objc(Affirmation)
public class Affirmation: NSManagedObject {
}

extension Affirmation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Affirmation> {
        return NSFetchRequest<Affirmation>(entityName: "Affirmation")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var category: String?
}
