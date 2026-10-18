//
//  AppTheme.swift
//  CS2 Cases
//
//  A small shared design system modeled on the CS2 menus: condensed type
//  (standing in for the game's Stratum2 face), flat rectangular buttons, and
//  a blurred concrete "map" backdrop behind every screen.
//

import SwiftUI

extension Color {
    static let appCanvas = Color(red: 0x10 / 255, green: 0x16 / 255, blue: 0x1b / 255)
    static let appSurface0 = Color(red: 0x12 / 255, green: 0x1b / 255, blue: 0x24 / 255)
    static let appSurface1 = Color(red: 0x18 / 255, green: 0x21 / 255, blue: 0x2a / 255)
    static let appSurface2 = Color(red: 0x22 / 255, green: 0x2c / 255, blue: 0x36 / 255)
    static let appDivider = Color(red: 0x2a / 255, green: 0x33 / 255, blue: 0x3d / 255)

    static let appTextSecondary = Color(red: 0xab / 255, green: 0xb2 / 255, blue: 0xb9 / 255)
    static let appTextTertiary = Color(red: 0x6b / 255, green: 0x74 / 255, blue: 0x80 / 255)

    /// The yellow-gold used for the reel marker and highlights in game.
    static let csGold = Color(red: 0xe4 / 255, green: 0xae / 255, blue: 0x39 / 255)
}

extension Font {
    /// The app's typeface: a condensed sans, the closest system match to the
    /// game's Stratum2.
    static func cs(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }
}

/// Generic press-down feedback for tiles and other non-button-looking taps.
struct PressableStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A Liquid Glass capsule button, in the style of the latest iOS: the label
/// floats on interactive glass that reacts to touch, optionally tinted for
/// emphasis.
struct CSButtonStyle: ButtonStyle {
    enum Kind {
        /// Green-tinted call-to-action (e.g. "Unlock Container").
        case primary
        /// Plain clear glass, for everything else.
        case secondary
        /// Glass tinted with an arbitrary color (e.g. the won item's rarity).
        case tinted(Color)
    }

    var kind: Kind = .secondary
    var compact = false
    var fullWidth = false

    @Environment(\.isEnabled) private var isEnabled

    private var glass: Glass {
        switch kind {
        case .primary:
            return .regular.tint(Color(red: 0.30, green: 0.62, blue: 0.22).opacity(isEnabled ? 0.85 : 0.35)).interactive()
        case .secondary:
            return .regular.interactive()
        case .tinted(let color):
            return .regular.tint(color.opacity(isEnabled ? 0.75 : 0.3)).interactive()
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cs(compact ? 15 : 17, .semibold))
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.5))
            .padding(.horizontal, compact ? 14 : 24)
            .padding(.vertical, compact ? 7 : 12)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .contentShape(Capsule())
            .glassEffect(glass, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    /// A rounded Liquid Glass panel behind this view.
    func glassPanel(cornerRadius: CGFloat = 24, tint: Color? = nil) -> some View {
        glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
    }
}

/// Stand-in for the blurred map behind the CS2 menus: a concrete warehouse
/// interior -- paneled walls with pillars and a lit doorway, a floor running
/// off to a vanishing point -- drawn procedurally (no map art is bundled),
/// then thrown out of focus like the game's depth-of-field backdrop.
struct CSBackground: View {
    /// Extra darkening, for screens with lots of foreground content.
    var dim: Double = 0

    var body: some View {
        ZStack {
            Canvas { context, size in
                drawScene(in: &context, size: size)
            }
            .blur(radius: 7)

            // Haze where the light hits, and darkened corners.
            RadialGradient(
                colors: [.white.opacity(0.16), .clear],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 420
            )
            RadialGradient(
                colors: [.clear, .black.opacity(0.55)],
                center: .center,
                startRadius: 220,
                endRadius: 760
            )
            Color.black.opacity(dim)
        }
        .drawingGroup()
    }

    private func drawScene(in context: inout GraphicsContext, size: CGSize) {
        let horizon = size.height * 0.6
        let wallRect = CGRect(x: 0, y: 0, width: size.width, height: horizon)
        let floorRect = CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon)

        // Concrete wall.
        context.fill(
            Path(wallRect),
            with: .linearGradient(
                Gradient(colors: [Color(red: 0.50, green: 0.53, blue: 0.56), Color(red: 0.62, green: 0.64, blue: 0.66)]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: horizon)
            )
        )

        // Panel seams and heavier pillars every few panels.
        let panelWidth: CGFloat = 70
        var x: CGFloat = -20
        var index = 0
        while x < size.width + panelWidth {
            if index % 4 == 0 {
                let pillar = CGRect(x: x - 14, y: 0, width: 28, height: horizon)
                context.fill(Path(pillar), with: .color(Color(white: 0.72).opacity(0.55)))
                context.fill(
                    Path(CGRect(x: pillar.maxX, y: 0, width: 10, height: horizon)),
                    with: .color(.black.opacity(0.18))
                )
            } else {
                context.fill(
                    Path(CGRect(x: x, y: 0, width: 1.5, height: horizon)),
                    with: .color(.black.opacity(0.15))
                )
            }
            x += panelWidth
            index += 1
        }

        // A lit doorway left of center and a dark opening on the right.
        context.fill(
            Path(CGRect(x: size.width * 0.18, y: horizon * 0.38, width: size.width * 0.09, height: horizon * 0.62)),
            with: .color(Color(red: 0.86, green: 0.84, blue: 0.78).opacity(0.7))
        )
        context.fill(
            Path(CGRect(x: size.width * 0.74, y: horizon * 0.45, width: size.width * 0.12, height: horizon * 0.55)),
            with: .color(Color(red: 0.18, green: 0.20, blue: 0.22).opacity(0.8))
        )

        // Grimy band along the base of the wall.
        context.fill(
            Path(CGRect(x: 0, y: horizon - 26, width: size.width, height: 26)),
            with: .color(Color(red: 0.32, green: 0.34, blue: 0.36).opacity(0.8))
        )

        // Floor.
        context.fill(
            Path(floorRect),
            with: .linearGradient(
                Gradient(colors: [Color(red: 0.40, green: 0.43, blue: 0.47), Color(red: 0.20, green: 0.22, blue: 0.25)]),
                startPoint: CGPoint(x: 0, y: horizon),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        // Painted floor lines converging on a vanishing point.
        let vanishing = CGPoint(x: size.width * 0.5, y: horizon)
        for i in -6...6 {
            var line = Path()
            line.move(to: vanishing)
            line.addLine(to: CGPoint(x: size.width * 0.5 + CGFloat(i) * size.width * 0.22, y: size.height))
            context.stroke(line, with: .color(.white.opacity(i.isMultiple(of: 3) ? 0.16 : 0.06)), lineWidth: 2)
        }
    }
}
