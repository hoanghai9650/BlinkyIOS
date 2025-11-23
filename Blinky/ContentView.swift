//
//  ContentView.swift
//  Blinky
//
//  Created by MacOS on 18/11/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var locationService = LocationService()

    var body: some View {
        RootPagerView()
            .environmentObject(locationService)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PhotoAsset.self, inMemory: true)
}
