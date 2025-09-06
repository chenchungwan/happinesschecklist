//
//  Happiness_ChecklistApp.swift
//  Happiness Checklist
//
//  Created by Christine Chen on 9/6/25.
//

import SwiftUI

@main
struct Happiness_ChecklistApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
