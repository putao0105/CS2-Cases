//
//  ContentView.swift
//  CS2 Cases
//
//  Created by 涂元侑 on 2026/10/15.
//

import SwiftUI

struct ContentView: View {
    @State private var showInventory = false

    var body: some View {
        NavigationStack {
            CaseSelectionView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showInventory = true
                        } label: {
                            Label("Inventory", systemImage: "shippingbox.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.cs(16, .semibold))
                        }
                    }
                }
        }
        .tint(.white)
        .sheet(isPresented: $showInventory) {
            InventoryView()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
        .environment(InventoryStore())
}
