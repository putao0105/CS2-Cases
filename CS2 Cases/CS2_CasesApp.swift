//
//  CS2_CasesApp.swift
//  CS2 Cases
//
//  Created by 涂元侑 on 2026/10/15.
//

import SwiftUI

@main
struct CS2_CasesApp: App {
    @State private var inventory = InventoryStore()

    init() {
        // The default shared cache is too small to hold skin images (URLCache
        // skips responses larger than ~5% of its capacity), which made the
        // prefetcher useless and left reel cards loading mid-spin.
        URLCache.shared = URLCache(memoryCapacity: 64 * 1024 * 1024, diskCapacity: 256 * 1024 * 1024)

        // Navigation titles use the same condensed face as the rest of the UI.
        let navBar = UINavigationBar.appearance()
        navBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold, width: .condensed)
        ]
        navBar.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold, width: .condensed)
        ]
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(inventory)
                // Catches any text that doesn't set an explicit `.cs` font
                // (e.g. empty-state views).
                .fontWidth(.condensed)
                .preferredColorScheme(.dark)
        }
    }
}
