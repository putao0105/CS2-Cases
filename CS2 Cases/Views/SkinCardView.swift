//
//  SkinCardView.swift
//  CS2 Cases
//
//  Item cards as Liquid Glass bubbles: the skin art on rarity-tinted glass,
//  a glowing rarity bar, and the weapon/skin name underneath.
//

import SwiftUI

struct SkinCardView: View {
    let skin: Skin
    var isGlowing: Bool = false

    private let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CachedSkinImage(url: skin.imageURL)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
                .padding(.horizontal, 6)
                .frame(height: 84)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topLeading) {
                    if let wear = skin.wear {
                        Text(wear.shortName)
                            .font(.cs(11, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .glassEffect(.regular.tint(wear.color.opacity(0.5)), in: Capsule())
                    }
                }

            // Rarity shown as a glowing capsule bar instead of a flat strip.
            Capsule()
                .fill(skin.rarity.color)
                .frame(height: 4)
                .shadow(color: skin.rarity.color.opacity(0.8), radius: 4)

            VStack(alignment: .leading, spacing: 1) {
                Text(skin.weaponName)
                    .font(.cs(14, .semibold))
                    .foregroundStyle(.white)
                Text(skin.skinName)
                    .font(.cs(12))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .lineLimit(1)
        }
        .padding(10)
        .glassEffect(.regular.tint(skin.rarity.color.opacity(0.18)), in: shape)
        .overlay(
            shape.strokeBorder(Color.white.opacity(0.9), lineWidth: isGlowing ? 2 : 0)
        )
        .shadow(color: skin.rarity.color.opacity(isGlowing ? 0.6 : 0), radius: 18)
        .scaleEffect(isGlowing ? 1.04 : 1)
    }
}

/// A reel card styled like the in-game spinner (gray tile, rarity glow
/// rising from the bottom, rarity bar), softened into a rounded bubble with
/// a glassy top sheen. Not real Liquid Glass: dozens of these fly past at
/// speed, which live glass isn't meant for. Sized by its container.
struct ReelItemView: View {
    let skin: Skin
    var isHighlighted: Bool = false

    private let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(white: 0.46), Color(white: 0.30)],
                startPoint: .top,
                endPoint: .bottom
            )
            rarityGlow

            if skin.rarity == .special {
                // Like the real game, knives/gloves never show their actual
                // image in the reel -- just the gold "Rare Special Item" card.
                RareItemCoin(size: 52)
                    .frame(maxHeight: .infinity)
            } else {
                CachedSkinImage(url: skin.imageURL)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .frame(maxHeight: .infinity)
            }

            Capsule()
                .fill(skin.rarity.color)
                .frame(height: 4)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
        }
        .clipShape(shape)
        .overlay(GlassSheen(shape: shape))
        .overlay(
            shape.strokeBorder(Color.white, lineWidth: isHighlighted ? 2.5 : 0)
        )
    }

    private var rarityGlow: some View {
        LinearGradient(
            colors: [.clear, skin.rarity.color.opacity(0.7)],
            startPoint: UnitPoint(x: 0.5, y: 0.45),
            endPoint: .bottom
        )
    }
}

/// A cheap imitation of glass for views that can't use live Liquid Glass:
/// a bright specular wash across the top and a thin light rim.
struct GlassSheen<S: InsettableShape>: View {
    let shape: S

    var body: some View {
        ZStack {
            shape.fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.28), location: 0),
                        .init(color: .white.opacity(0.05), location: 0.35),
                        .init(color: .clear, location: 0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            shape.strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.55), .white.opacity(0.08), .white.opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    HStack {
        SkinCardView(skin: CaseData.recoilCase.skins.last!, isGlowing: true)
            .frame(width: 140)
        ReelItemView(skin: CaseData.recoilCase.skins[0])
            .frame(width: 132, height: 112)
        ReelItemView(skin: CaseData.recoilCase.skins.last!)
            .frame(width: 132, height: 112)
    }
    .padding()
    .background(Color(red: 0x12 / 255, green: 0x1b / 255, blue: 0x24 / 255))
}
