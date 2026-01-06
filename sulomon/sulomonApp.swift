//
//  sulomonApp.swift
//  sulomon
//
//  Created by 임정훈 on 1/6/26.
//

import SwiftUI
import SwiftData

@main
struct sulomonApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Person.self,
            DrinkRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
