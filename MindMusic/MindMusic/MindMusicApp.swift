//
//  MindMusicApp.swift
//  MindMusic
//
//  Created by Malmi Perera on 2025-11-25.
//

import SwiftUI
import CoreData

@main
struct MindMusicApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
