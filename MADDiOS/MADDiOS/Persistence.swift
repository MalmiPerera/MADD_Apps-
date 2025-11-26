//
//  Persistence.swift
//  MADDiOS
//
//  Created by Malmi Perera on 2025-11-06.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Seed a couple of preview affirmations if the entity exists in the model
        if entityExists("Affirmation", in: viewContext) {
            let a1 = Affirmation(context: viewContext); a1.id = UUID(); a1.text = "I am healing at my own pace."; a1.category = "growth"
            let a2 = Affirmation(context: viewContext); a2.id = UUID(); a2.text = "My heart is learning to trust again."; a2.category = "self-love"
            do { try viewContext.save() } catch { print("Preview save error: \(error)") }
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // Force programmatic model to avoid any broken .xcdatamodeld taking precedence
        print("[Persistence] Building programmatic Core Data model (forced)")
        let model: NSManagedObjectModel = Self.buildProgrammaticModel()
        container = NSPersistentCloudKitContainer(name: "AppDataModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("[Persistence] Persistent stores loaded: \(storeDescription.type)")
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        seedAffirmationsIfNeeded(in: container.viewContext)
    }

    // MARK: - Save helper
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do { try context.save() } catch { print("CoreData save error: \(error)") }
    }

    // MARK: - Model helpers
    private static func entityExists(_ name: String, in context: NSManagedObjectContext) -> Bool {
        context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[name] != nil
    }

    // MARK: - Programmatic model fallback
    private static func buildProgrammaticModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // JournalEntry entity
        let journalEntity = NSEntityDescription()
        journalEntity.name = "JournalEntry"
        journalEntity.managedObjectClassName = "JournalEntry"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = true

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = true

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = true

        let textAttr = NSAttributeDescription()
        textAttr.name = "text"
        textAttr.attributeType = .stringAttributeType
        textAttr.isOptional = true

        let scoreAttr = NSAttributeDescription()
        scoreAttr.name = "sentimentScore"
        scoreAttr.attributeType = .doubleAttributeType
        scoreAttr.isOptional = false
        scoreAttr.defaultValue = 0.0

        journalEntity.properties = [idAttr, dateAttr, titleAttr, textAttr, scoreAttr]

        // FocusSession entity
        let focusEntity = NSEntityDescription()
        focusEntity.name = "FocusSession"
        focusEntity.managedObjectClassName = "FocusSession"

        let focusIdAttr = NSAttributeDescription()
        focusIdAttr.name = "id"
        focusIdAttr.attributeType = .UUIDAttributeType
        focusIdAttr.isOptional = true

        let startAttr = NSAttributeDescription()
        startAttr.name = "start"
        startAttr.attributeType = .dateAttributeType
        startAttr.isOptional = true

        let endAttr = NSAttributeDescription()
        endAttr.name = "end"
        endAttr.attributeType = .dateAttributeType
        endAttr.isOptional = true

        let durationAttr = NSAttributeDescription()
        durationAttr.name = "durationSeconds"
        durationAttr.attributeType = .integer32AttributeType
        durationAttr.isOptional = false
        durationAttr.defaultValue = 0

        let noteAttr = NSAttributeDescription()
        noteAttr.name = "note"
        noteAttr.attributeType = .stringAttributeType
        noteAttr.isOptional = true

        focusEntity.properties = [focusIdAttr, startAttr, endAttr, durationAttr, noteAttr]

        // Affirmation entity
        let affirmEntity = NSEntityDescription()
        affirmEntity.name = "Affirmation"
        affirmEntity.managedObjectClassName = "Affirmation"

        let affirmIdAttr = NSAttributeDescription()
        affirmIdAttr.name = "id"
        affirmIdAttr.attributeType = .UUIDAttributeType
        affirmIdAttr.isOptional = true

        let affirmTextAttr = NSAttributeDescription()
        affirmTextAttr.name = "text"
        affirmTextAttr.attributeType = .stringAttributeType
        affirmTextAttr.isOptional = true

        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.isOptional = true

        affirmEntity.properties = [affirmIdAttr, affirmTextAttr, categoryAttr]

        model.entities = [journalEntity, focusEntity, affirmEntity]
        return model
    }

    // MARK: - Seed affirmations
    private func seedAffirmationsIfNeeded(in context: NSManagedObjectContext) {
        // If the entity isn't present yet (user hasn't updated .xcdatamodeld), skip seeding gracefully
        guard PersistenceController.entityExists("Affirmation", in: context) else {
            print("[Persistence] Skipping affirmations seed: 'Affirmation' entity not found")
            return
        }
        let req: NSFetchRequest<Affirmation> = Affirmation.fetchRequest()
        req.fetchLimit = 1
        if let count = try? context.count(for: req), count > 0 {
            print("[Persistence] Affirmations already seeded")
            return
        }

        let samples: [(String, String)] = [
            ("I release what no longer serves my peace.", "growth"),
            ("I am worthy of a love that feels safe and kind.", "self-love"),
            ("Every day, my heart grows lighter.", "hope"),
            ("I honor my feelings and allow them to pass.", "mindfulness"),
            ("Healing is not linear, and that’s okay.", "growth"),
            ("I choose to nurture myself today.", "self-love"),
            ("I am learning from this and moving forward.", "resilience"),
            ("My future holds new joy and connection.", "hope"),
            ("I am enough, exactly as I am.", "self-love"),
            ("I trust that better days are ahead.", "hope"),
            ("I give myself permission to rest.", "care"),
            ("I am creating space for what I deserve.", "growth"),
            ("I gently let go of what I cannot control.", "mindfulness"),
            ("I am safe in my own company.", "self-love"),
            ("I will love again, when I’m ready.", "hope")
        ]

        for (text, category) in samples {
            let a = Affirmation(context: context)
            a.id = UUID(); a.text = text; a.category = category
        }
        do { try context.save(); print("[Persistence] Seeded \(samples.count) affirmations") } catch { print("Seed affirmations save error: \(error)") }
    }
}
