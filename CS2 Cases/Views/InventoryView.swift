//
//  InventoryView.swift
//  CS2 Cases
//

import SwiftUI

struct InventoryView: View {
    @Environment(InventoryStore.self) private var inventory
    @Environment(\.dismiss) private var dismiss
    @State private var inspectedSkin: Skin?

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if inventory.unboxedSkins.isEmpty {
                    ContentUnavailableView(
                        "No Skins Yet",
                        systemImage: "shippingbox",
                        description: Text("Open a case to start your collection.")
                    )
                } else {
                    ScrollView {
                        // Renders all the glass cards together, which is
                        // much cheaper than many standalone glass effects.
                        // (Container spacing is kept below the grid spacing
                        // so neighboring cards don't melt into each other.)
                        GlassEffectContainer(spacing: 4) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(inventory.unboxedSkins) { skin in
                                    Button {
                                        inspectedSkin = skin
                                    } label: {
                                        SkinCardView(skin: skin)
                                    }
                                    .buttonStyle(PressableStyle())
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(CSBackground(dim: 0.45).ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // The system close button: a glass ✕ bubble. (A custom
                // text style here got squeezed into an icon-sized slot and
                // truncated to "D…".)
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
        .fullScreenCover(item: $inspectedSkin) { skin in
            SkinInspectView(skin: skin)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    InventoryView()
        .environment(InventoryStore())
}
