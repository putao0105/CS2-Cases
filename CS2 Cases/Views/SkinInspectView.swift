//
//  SkinInspectView.swift
//  CS2 Cases
//
//  Full-screen item preview, modeled on CS2's inspect screen: the skin large
//  in the middle of the scene, its name/rarity/exterior up top and the wear
//  rating along the bottom. The in-game inspect is 3D; with a flat image we
//  approximate it by tilting the art in 3D as you drag, plus pinch to zoom.
//

import SwiftUI

struct SkinInspectView: View {
    let skin: Skin
    @Environment(\.dismiss) private var dismiss

    /// Accumulated drag, in points; converted to tilt angles below.
    @State private var tilt: CGSize = .zero
    @GestureState private var dragDelta: CGSize = .zero
    @State private var zoom: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1

    private var totalTilt: CGSize {
        CGSize(width: tilt.width + dragDelta.width, height: tilt.height + dragDelta.height)
    }

    var body: some View {
        ZStack {
            CSBackground(dim: 0.3).ignoresSafeArea()

            // Soft glow of the rarity color behind the item.
            RadialGradient(
                colors: [skin.rarity.color.opacity(0.35), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                header

                inspectableImage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let float = skin.floatValue {
                    WearRatingView(float: float)
                        .frame(maxWidth: 520)
                }

                Text("Drag to rotate · Pinch to zoom · Double-tap to reset")
                    .font(.cs(11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(skin.weaponName) | \(skin.skinName)")
                    .font(.cs(26, .semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(skin.rarity.displayName)
                        .foregroundStyle(skin.rarity.color)
                    if let wear = skin.wear {
                        Text("·").foregroundStyle(.white.opacity(0.5))
                        Text(wear.displayName).foregroundStyle(.white.opacity(0.85))
                    }
                }
                .font(.cs(14, .semibold))
            }
            .shadow(color: .black.opacity(0.5), radius: 4)

            Spacer()

            Button("Close") { dismiss() }
                .buttonStyle(CSButtonStyle(compact: true))
        }
    }

    private var inspectableImage: some View {
        CachedSkinImage(url: skin.imageURL)
            .shadow(color: .black.opacity(0.5), radius: 16, y: 12)
            .scaleEffect(min(max(zoom * pinch, 1), 3))
            .rotation3DEffect(
                .degrees(clamp(Double(totalTilt.width) / 4, limit: 40)),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
            .rotation3DEffect(
                .degrees(clamp(Double(-totalTilt.height) / 4, limit: 25)),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.6
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($dragDelta) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        // Keep the accumulated drag within the visible tilt
                        // limits so reversing direction responds immediately.
                        tilt.width = clamp(tilt.width + value.translation.width, limit: 160)
                        tilt.height = clamp(tilt.height + value.translation.height, limit: 100)
                    }
                    .simultaneously(with:
                        MagnifyGesture()
                            .updating($pinch) { value, state, _ in state = value.magnification }
                            .onEnded { value in zoom = min(max(zoom * value.magnification, 1), 3) }
                    )
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    tilt = .zero
                    zoom = 1
                }
            }
    }

    private func clamp<T: BinaryFloatingPoint>(_ value: T, limit: T) -> T {
        min(max(value, -limit), limit)
    }
}

/// "Wear Rating": the exact float plus the game's segmented wear bar with a
/// marker showing where this float sits.
struct WearRatingView: View {
    let float: Double

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Wear Rating")
                    .font(.cs(11, .semibold))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(Color.appTextSecondary)
                Text(String(format: "%.9f", float))
                    .font(.cs(17, .semibold).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .fixedSize()

            WearBar(float: float)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .glassEffect(in: Capsule())
    }
}

/// Five colored segments sized by each exterior's float range, with a white
/// marker at the item's float.
struct WearBar: View {
    let float: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .topLeading) {
                HStack(spacing: 1) {
                    ForEach(Wear.allCases, id: \.self) { wear in
                        Rectangle()
                            .fill(wear.color)
                            .frame(width: max(width * (wear.range.upperBound - wear.range.lowerBound) - 1, 0))
                    }
                }
                .frame(height: 6)
                .clipShape(Capsule())
                .offset(y: 9)

                // Marker: a small downward triangle over a line.
                VStack(spacing: 0) {
                    MarkerTriangle()
                        .fill(.white)
                        .frame(width: 10, height: 7)
                    Rectangle()
                        .fill(.white)
                        .frame(width: 2, height: 10)
                }
                .shadow(color: .black.opacity(0.6), radius: 1)
                .offset(x: width * min(max(float, 0), 1) - 5)
            }
        }
        .frame(height: 20)
    }
}

private struct MarkerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview(traits: .landscapeLeft) {
    SkinInspectView(skin: CaseData.recoilCase.skins[15].unboxed())
}
