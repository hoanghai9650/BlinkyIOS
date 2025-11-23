//
//  BlinkyApp.swift
//  Blinky
//
//  Created by MacOS on 18/11/25.
//

import SwiftUI
import SwiftData

@main
struct BlinkyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PhotoAsset.self
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
