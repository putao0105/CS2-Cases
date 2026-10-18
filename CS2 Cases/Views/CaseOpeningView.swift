//
//  CaseOpeningView.swift
//  CS2 Cases
//
//  The classic CS2/CS:GO case-opening flow: confirm on the case, then a
//  horizontal reel spins past a center marker and eases to a stop on the
//  won item. This is the original slot-machine reveal, not the newer X-Ray
//  scan mechanic.
//
//  Like the real game, the result is rolled *first* (using the official
//  rarity odds); the reel is then built around it and animated to land on
//  it, stopping at a random point inside the winning tile rather than dead
//  center.
//

import Foundation
import SwiftUI

struct CaseOpeningView: View {
    let caseItem: WeaponCase
    @Environment(InventoryStore.self) private var inventory

    private enum Stage {
        case idle
        case opening
        case spinning
        case landed
    }

    private let itemWidth: CGFloat = 132
    private let itemSpacing: CGFloat = 10
    private let horizontalPadding: CGFloat = 16
    private let reelHeight: CGFloat = 112
    private var stride: CGFloat { itemWidth + itemSpacing }

    /// Index of the winning item in the strip -- enough lead-in cards that
    /// the reel visibly travels a long way before slowing down.
    private let winnerIndex = 40
    private let spinDuration = 6.0
    /// Pause on the stopped reel before the reveal pops up, so the player can
    /// see where the marker landed.
    private let landedPause = 0.7

    // Real screen width, captured once at the top level so it's valid
    // before the reel has ever been shown. reelWidth is what cards/marker
    // actually have to work with, after the reel's own horizontal padding.
    @State private var containerWidth: CGFloat = 0
    private var reelWidth: CGFloat { max(containerWidth - horizontalPadding * 2 - reelInset * 2, 0) }
    /// Padding between the reel and the glass track around it.
    private let reelInset: CGFloat = 8

    @State private var stage: Stage = .idle
    @State private var boxOpening = false
    @State private var imagesReady = false

    @State private var reel: [Skin] = []
    @State private var reelOffset: CGFloat = 0
    @State private var targetOffset: CGFloat?
    @State private var winner: Skin?
    @State private var revealedSkin: Skin?
    @State private var inspectedSkin: Skin?
    @State private var spinTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { outerGeo in
            Group {
                if stage == .spinning || stage == .landed {
                    spinningView
                } else {
                    boxView(height: outerGeo.size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { containerWidth = outerGeo.size.width }
            .onChange(of: outerGeo.size.width) { _, newWidth in containerWidth = newWidth }
        }
        .background(CSBackground().ignoresSafeArea())
        .preferredColorScheme(.dark)
        // The page draws its own "Unlock Container" / case-name header.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // Leaving mid-spin would orphan the animation; the real game also
        // locks you into the unbox once it starts.
        .navigationBarBackButtonHidden(stage != .idle)
        .task {
            // The whole case's pool is only ~19 images -- load and decode all
            // of them before the first spin so every card on the reel shows
            // its skin the entire time, not just once the reel slows down.
            await SkinImageStore.shared.preload(caseItem.skins.compactMap(\.imageURL))
            imagesReady = true
        }
        .onDisappear {
            spinTask?.cancel()
            spinTask = nil
        }
        .overlay {
            if let revealedSkin {
                RevealOverlay(
                    skin: revealedSkin,
                    onInspect: { inspectedSkin = revealedSkin },
                    onDismiss: reset
                )
            }
        }
        .fullScreenCover(item: $inspectedSkin) { skin in
            SkinInspectView(skin: skin)
        }
    }

    // MARK: - Shared pieces

    private var header: some View {
        VStack(spacing: 2) {
            Text("Unlock Container")
                .font(.cs(28, .semibold))
                .foregroundStyle(.white)
            Text("Unlock \(Text(caseItem.name).fontWeight(.bold))")
                .font(.cs(14))
                .foregroundStyle(.white.opacity(0.85))
        }
        .shadow(color: .black.opacity(0.5), radius: 4)
        .padding(.top, 8)
    }

    private var caseImage: some View {
        AsyncImage(url: caseItem.imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView().tint(.white)
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.4))
            @unknown default:
                EmptyView()
            }
        }
    }

    // MARK: - Spinning

    /// The in-game opening phase: the header stays put, the case sits
    /// blurred behind a dark circular lens, and the reel runs across it.
    private var spinningView: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 8)

            reelView(width: reelWidth)
                .padding(reelInset)
                .glassPanel(cornerRadius: 30)
                .padding(.horizontal, horizontalPadding)
                // In a background so the oversized case/lens can spill past
                // the reel without pushing the rest of the layout around.
                .background {
                    ZStack {
                        caseImage
                            .frame(height: reelHeight * 1.9)
                            .blur(radius: 6)
                            .opacity(0.8)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.black.opacity(0.55), .black.opacity(0.35), .black.opacity(0.1)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: reelHeight * 1.1
                                )
                            )
                            .frame(width: reelHeight * 2.2, height: reelHeight * 2.2)
                    }
                    .allowsHitTesting(false)
                }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                Image(systemName: "key.fill")
                    .foregroundStyle(Color.csGold)
                Text("Use \(Text(caseItem.name + " Key").fontWeight(.bold))")
                    .font(.cs(13))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                if stage == .spinning {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Button("Close") {}
                    .buttonStyle(CSButtonStyle(compact: true))
                    .disabled(true)
            }
            .padding(.leading, 18)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .glassEffect(in: Capsule())
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Box

    /// Mirrors the in-game "Unlock Container" screen: title up top, the case
    /// sitting in the scene, and a dark contents panel along the bottom.
    private func boxView(height: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                caseImage
                .shadow(color: .black.opacity(0.45), radius: 12, y: 10)
                .frame(height: min(max(height * 0.38, 110), 280))
                .padding(.vertical, 8)
                .scaleEffect(boxOpening ? 1.25 : 1)
                .opacity(boxOpening ? 0 : 1)

                Spacer(minLength: 0)

                ContainerContentsView(caseItem: caseItem) {
                    Button(imagesReady ? "Unlock Container" : "Loading…", action: beginOpening)
                        .buttonStyle(CSButtonStyle(kind: .primary))
                        .opacity(stage == .idle ? (imagesReady ? 1 : 0.5) : 0)
                        .disabled(stage != .idle || !imagesReady)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                // A floating glass sheet instead of a flat dark strip.
                .glassPanel(cornerRadius: 30, tint: .black.opacity(0.3))
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 8)
            }
            .frame(minHeight: height)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func beginOpening() {
        guard stage == .idle, imagesReady, reelWidth > 0 else { return }

        // Roll first, then build the reel around the result.
        let rolled = caseItem.rollSkin().unboxed()
        // Grant the item immediately, as the game does -- the animation is
        // purely cosmetic and must never be able to lose a drop.
        inventory.add(rolled)
        winner = rolled

        // Filler cards are drawn with the same rarity odds, so the reel is
        // mostly blues with the occasional purple/pink, like the real thing.
        let visibleCount = Int((reelWidth / stride).rounded(.up))
        let trailCount = visibleCount / 2 + 3
        var strip = (0..<winnerIndex).map { _ in caseItem.rollSkin() }
        strip.append(rolled)
        strip.append(contentsOf: (0..<trailCount).map { _ in caseItem.rollSkin() })
        reel = strip

        // Land at a random point inside the winning tile (never on its
        // edge), so it isn't always perfectly centered under the marker.
        let jitter = CGFloat.random(in: -0.42...0.42) * itemWidth
        let winnerCenter = CGFloat(winnerIndex) * stride + itemWidth / 2
        reelOffset = 0
        targetOffset = winnerCenter + jitter - reelWidth / 2

        stage = .opening
        withAnimation(.easeIn(duration: 0.3)) {
            boxOpening = true
        }
        spinTask = Task {
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            // The reel's onAppear kicks off the spin, which guarantees it
            // has been rendered at offset 0 before animating away from it.
            stage = .spinning
        }
    }

    // MARK: - Reel

    private func reelView(width: CGFloat) -> some View {
        ZStack {
            reelStrip
                .frame(width: width, height: reelHeight, alignment: .leading)
                // Cards fade out toward both ends, as in game.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.18),
                            .init(color: .black, location: 0.82),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // The thin yellow center line.
            Rectangle()
                .fill(Color.csGold)
                .frame(width: 2, height: reelHeight)
                .shadow(color: Color.csGold.opacity(0.8), radius: 3)
                .position(x: width / 2, y: reelHeight / 2)
        }
        .frame(width: width, height: reelHeight)
        .clipShape(.rect(cornerRadius: 22))
        .onAppear(perform: startSpin)
    }

    private var reelStrip: some View {
        // Highlighting the exact card that stopped at the marker makes the
        // correspondence to the reveal popup undeniable.
        let highlightIndex = stage == .landed ? winnerIndex : nil
        return HStack(spacing: itemSpacing) {
            ForEach(Array(reel.enumerated()), id: \.offset) { index, skin in
                ReelItemView(skin: skin, isHighlighted: index == highlightIndex)
                    .frame(width: itemWidth, height: reelHeight)
            }
        }
        // The strip is far wider than the reel; keep its natural width so
        // its leading edge sits at x = 0, which the offset math relies on.
        .fixedSize()
        .offset(x: -reelOffset)
    }

    private func startSpin() {
        guard stage == .spinning, let target = targetOffset else { return }
        targetOffset = nil
        SoundEffect.spinStart()

        let start = reelOffset
        let tickTimes = tickTimes(from: start, to: target)

        withAnimation(Animation(QuarticEaseOut(duration: spinDuration))) {
            reelOffset = target
        }

        spinTask = Task {
            let clock = ContinuousClock()
            let spinStart = clock.now
            do {
                for time in tickTimes {
                    try await Task.sleep(until: spinStart.advanced(by: .seconds(time)), clock: clock)
                    SoundEffect.tick()
                }
                try await Task.sleep(until: spinStart.advanced(by: .seconds(spinDuration)), clock: clock)
                stage = .landed

                try await Task.sleep(for: .seconds(landedPause))
                guard let winner else { return }
                revealedSkin = winner
                SoundEffect.reveal(rarity: winner.rarity)
            } catch {
                // Cancelled (view went away) -- the item is already in the
                // inventory, so there's nothing to clean up.
            }
        }
    }

    /// The moments a card boundary crosses the marker, computed analytically
    /// from the same easing curve driving the visual motion -- so each click
    /// is tied to the reel actually advancing onto a new card.
    private func tickTimes(from start: CGFloat, to end: CGFloat) -> [Double] {
        let distance = end - start
        guard distance > 0 else { return [] }

        // Marker position in strip coordinates at the start and end.
        let markerStart = start + reelWidth / 2
        let markerEnd = end + reelWidth / 2

        // Boundaries are the centers of the gaps between cards.
        let firstK = Int(((markerStart + itemSpacing / 2) / stride).rounded(.down)) + 1
        let lastK = Int(((markerEnd + itemSpacing / 2) / stride).rounded(.down))
        guard firstK <= lastK else { return [] }

        return (firstK...lastK).map { k in
            let boundary = CGFloat(k) * stride - itemSpacing / 2
            let fraction = Double((boundary - markerStart) / distance)
            // Inverse of eased = 1 - (1 - t)^4.
            return (1 - pow(1 - fraction, 0.25)) * spinDuration
        }
    }

    private func reset() {
        spinTask?.cancel()
        spinTask = nil
        revealedSkin = nil
        winner = nil
        reel = []
        reelOffset = 0
        targetOffset = nil
        stage = .idle
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            boxOpening = false
        }
    }
}

/// Matches the quartic ease-out used for the reel: fast at first, slowing
/// sharply into the stop. Using `CustomAnimation` (rather than approximating
/// with a cubic-bezier `.timingCurve`) keeps the visual motion and the
/// analytically-scheduled tick sounds perfectly in sync.
private struct QuarticEaseOut: CustomAnimation {
    let duration: Double

    func animate<V: VectorArithmetic>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? {
        guard duration > 0, time < duration else { return nil }
        let progress = time / duration
        let eased = 1 - pow(1 - progress, 4)
        return value.scaled(by: eased)
    }
}

private struct RevealOverlay: View {
    let skin: Skin
    let onInspect: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false

    private var isRare: Bool { skin.rarity >= .covert }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            if isRare {
                ConfettiBurstView(color: skin.rarity.color)
            }

            // Card beside the details, all on one floating glass sheet --
            // side by side so it fits comfortably in landscape.
            HStack(spacing: 22) {
                SkinCardView(skin: skin, isGlowing: true)
                    .frame(width: 190)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(skin.rarity.displayName)
                            .font(.cs(13, .semibold))
                            .tracking(1)
                            .foregroundStyle(skin.rarity.color)
                            .textCase(.uppercase)
                        Text("\(skin.weaponName) | \(skin.skinName)")
                            .font(.cs(24, .semibold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let wear = skin.wear, let float = skin.formattedFloat {
                        HStack(spacing: 8) {
                            Text(wear.displayName)
                                .font(.cs(13, .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .glassEffect(.regular.tint(wear.color.opacity(0.55)), in: Capsule())
                            Text("Float \(float)")
                                .font(.cs(14, .semibold).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .foregroundStyle(.white)
                    }

                    GlassEffectContainer(spacing: 4) {
                        HStack(spacing: 12) {
                            Button("Inspect", action: onInspect)
                                .buttonStyle(CSButtonStyle())
                            Button("Collect", action: onDismiss)
                                .buttonStyle(CSButtonStyle(kind: .tinted(skin.rarity.color)))
                        }
                    }
                }
                .frame(maxWidth: 300, alignment: .leading)
            }
            .padding(22)
            .glassPanel(cornerRadius: 36, tint: .black.opacity(0.35))
            .padding(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack {
        CaseOpeningView(caseItem: CaseData.recoilCase)
    }
    .environment(InventoryStore())
}

#Preview("Reveal", traits: .landscapeLeft) {
    ZStack {
        CSBackground().ignoresSafeArea()
        RevealOverlay(skin: CaseData.recoilCase.skins[15].unboxed(), onInspect: {}, onDismiss: {})
    }
}
