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
            ContentView(viewModel: DailyEntryViewModel(context: persistenceController.container.viewContext))
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Kick off CloudKit sync early
                    _ = persistenceController.container.viewContext
                }
        }
    }
}
