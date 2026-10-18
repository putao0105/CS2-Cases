//
//  ContainerContentsView.swift
//  CS2 Cases
//
//  The "Contains one of the following:" grid from the in-game Unlock
//  Container screen: every regular skin sorted from Mil-Spec up to Covert,
//  each on a small glassy tile with a rarity bar, and all knives / gloves
//  collapsed into a single gold "Special Item" tile at the end.
//

import SwiftUI

struct ContainerContentsView<Accessory: View>: View {
    let caseItem: WeaponCase
    /// Shown at the trailing end of the header row (the unlock button).
    @ViewBuilder var accessory: Accessory

    private let columns = [GridItem(.adaptive(minimum: 62, maximum: 96), spacing: 8)]

    private var regularSkins: [Skin] {
        caseItem.skins
            .filter { $0.rarity != .special }
            .sorted { $0.rarity < $1.rarity }
    }

    private var hasSpecialItems: Bool {
        caseItem.skins.contains { $0.rarity == .special }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Contains one of the following:")
                    .font(.cs(13, .medium))
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                accessory
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(regularSkins) { skin in
                    ContainerItemTile(skin: skin)
                }
                if hasSpecialItems {
                    RareSpecialItemTile()
                }
            }
        }
    }
}

private struct ContainerItemTile: View {
    let skin: Skin

    var body: some View {
        ContentsTile(rarity: skin.rarity, title: skin.weaponName, subtitle: skin.skinName) {
            CachedSkinImage(url: skin.imageURL)
                .padding(6)
        }
    }
}

/// Same tile as every other item, just with the gold coin in place of a
/// skin image.
private struct RareSpecialItemTile: View {
    var body: some View {
        ContentsTile(rarity: .special, title: "Special Item", subtitle: "Very Rare") {
            RareItemCoin(size: 32)
        }
    }
}

/// A small rounded, glassy bubble: art on a translucent well with a sheen,
/// a glowing rarity capsule along its bottom, and two lines of text below.
private struct ContentsTile<Art: View>: View {
    let rarity: Rarity
    let title: String
    let subtitle: String
    @ViewBuilder var art: Art

    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .bottom) {
                shape.fill(
                    LinearGradient(
                        colors: [.white.opacity(0.14), rarity.color.opacity(0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                art
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Capsule()
                    .fill(rarity.color)
                    .frame(height: 3)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                    .shadow(color: rarity.color, radius: 3)
            }
            .frame(height: 52)
            .clipShape(shape)
            .overlay(GlassSheen(shape: shape))

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.cs(11, .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.cs(10))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .lineLimit(1)
            .padding(.horizontal, 2)
        }
    }
}

/// The game's gold coin with a question mark, standing in for any knife or
/// glove until it's revealed.
struct RareItemCoin: View {
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.86, blue: 0.45), Color(red: 0.85, green: 0.62, blue: 0.18)],
                    center: UnitPoint(x: 0.35, y: 0.3),
                    startRadius: 0,
                    endRadius: size * 0.7
                )
            )
            .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: max(size / 17, 1.5)))
            .overlay(
                Text("?")
                    .font(.cs(size * 0.55, .heavy))
                    .foregroundStyle(.white)
            )
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            .frame(width: size, height: size)
    }
}

/// Draws a skin image from the preloaded `SkinImageStore`, falling back to
/// `AsyncImage` if it hasn't been loaded (or failed to).
struct CachedSkinImage: View {
    let url: URL?

    var body: some View {
        if let image = SkinImageStore.shared.image(for: url) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.gray)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    Image(systemName: "photo")
                        .foregroundStyle(.gray.opacity(0.4))
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContainerContentsView(caseItem: CaseData.fractureCase) { EmptyView() }
        .padding()
        .background(Color.black)
}
