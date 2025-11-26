import XCTest
import CoreData
@testable import MADDiOS

final class InsightsViewModelTests: XCTestCase {
    private func inMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "MADDiOS")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        return container
    }

    func testAggregation() throws {
        let container = inMemoryContainer()
        let ctx = container.viewContext

        // Create 2 focus sessions: 10min and 20min today
        let s1 = FocusSession(context: ctx)
        s1.id = UUID(); s1.start = Date().addingTimeInterval(-1200); s1.end = Date(); s1.durationSeconds = 600
        let s2 = FocusSession(context: ctx)
        s2.id = UUID(); s2.start = Date().addingTimeInterval(-1800); s2.end = Date(); s2.durationSeconds = 1200

        // Create 2 journal entries: sentiments -0.5 and 0.5
        let e1 = JournalEntry(context: ctx); e1.id = UUID(); e1.date = Date(); e1.title = "A"; e1.text = "..."; e1.sentimentScore = -0.5
        let e2 = JournalEntry(context: ctx); e2.id = UUID(); e2.date = Date(); e2.title = "B"; e2.text = "..."; e2.sentimentScore = 0.5

        try ctx.save()

        let vm = InsightsViewModel()
        vm.fetch(context: ctx)

        let totalMinutes = Int(vm.dailyFocusMinutes.map { $0.value }.reduce(0, +))
        XCTAssertEqual(totalMinutes, 30)

        let avg = (vm.entries.map { $0.sentimentScore }.reduce(0, +)) / Double(vm.entries.count)
        XCTAssertEqual(avg, 0.0, accuracy: 0.0001)

        XCTAssertFalse(vm.dailyFocusMinutes.isEmpty)
        XCTAssertFalse(vm.dailyAverageSentiment.isEmpty)
    }
}
