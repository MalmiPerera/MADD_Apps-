//
//  MADDiOSApp.swift
//  MADDiOS
//
//  Created by Malmi Perera on 2025-11-06.
//

import SwiftUI
import CoreData

@main
struct MADDiOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
