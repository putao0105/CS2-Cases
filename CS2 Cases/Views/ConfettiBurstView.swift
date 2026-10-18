//
//  ConfettiBurstView.swift
//  CS2 Cases
//

import SwiftUI
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// Small celebratory burst shown behind rare pulls, mirroring the classic
/// CS2 reveal flash for Covert/Extraordinary items.
struct ConfettiBurstView: View {
    let color: Color

    private struct Particle: Identifiable {
        let id = Int.random(in: Int.min...Int.max)
        let angle: Double
        let distance: CGFloat
        let symbolName: String
        let delay: Double

        var offsetX: CGFloat { CGFloat(cos(angle)) * distance }
        var offsetY: CGFloat { CGFloat(sin(angle)) * distance }
    }

    @State private var particles: [Particle] = []
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: particle.symbolName)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                    .offset(
                        x: animate ? particle.offsetX : 0,
                        y: animate ? particle.offsetY : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1.2 : 0.2)
                    .animation(.easeOut(duration: 1.1).delay(particle.delay), value: animate)
            }
        }
        .onAppear {
            particles = (0..<24).map { i in
                Particle(
                    angle: Double(i) / 24.0 * 2 * .pi,
                    distance: CGFloat.random(in: 80...140),
                    symbolName: ["sparkle", "star.fill", "diamond.fill"].randomElement()!,
                    delay: Double.random(in: 0...0.15)
                )
            }
            animate = true
        }
    }
}
