//
//  Wear.swift
//  CS2 Cases
//
//  CS2 skin wear: every unboxed skin gets a float value in 0...1, and the
//  float decides its exterior. The game first picks a wear tier with fixed
//  odds, then a uniform float inside that tier, then maps it into the
//  skin's own min/max float range.
//

import SwiftUI

enum Wear: CaseIterable {
    case factoryNew
    case minimalWear
    case fieldTested
    case wellWorn
    case battleScarred

    /// Float range covered by this exterior.
    var range: ClosedRange<Double> {
        switch self {
        case .factoryNew: return 0.00...0.07
        case .minimalWear: return 0.07...0.15
        case .fieldTested: return 0.15...0.38
        case .wellWorn: return 0.38...0.45
        case .battleScarred: return 0.45...1.00
        }
    }

    var displayName: String {
        switch self {
        case .factoryNew: return "Factory New"
        case .minimalWear: return "Minimal Wear"
        case .fieldTested: return "Field-Tested"
        case .wellWorn: return "Well-Worn"
        case .battleScarred: return "Battle-Scarred"
        }
    }

    var shortName: String {
        switch self {
        case .factoryNew: return "FN"
        case .minimalWear: return "MW"
        case .fieldTested: return "FT"
        case .wellWorn: return "WW"
        case .battleScarred: return "BS"
        }
    }

    /// Segment color on the wear bar, green (pristine) through red (worn).
    var color: Color {
        switch self {
        case .factoryNew: return Color(red: 0.36, green: 0.74, blue: 0.28)
        case .minimalWear: return Color(red: 0.60, green: 0.78, blue: 0.24)
        case .fieldTested: return Color(red: 0.90, green: 0.78, blue: 0.22)
        case .wellWorn: return Color(red: 0.92, green: 0.52, blue: 0.20)
        case .battleScarred: return Color(red: 0.86, green: 0.28, blue: 0.24)
        }
    }

    /// Chance of each tier being picked before the float is rolled.
    private var tierWeight: Double {
        switch self {
        case .factoryNew: return 0.03
        case .minimalWear: return 0.24
        case .fieldTested: return 0.33
        case .wellWorn: return 0.24
        case .battleScarred: return 0.16
        }
    }

    init(float: Double) {
        self = Wear.allCases.first { float < $0.range.upperBound } ?? .battleScarred
    }

    /// Rolls a float the way CS2 does, mapped into `skinRange` (most skins
    /// use the full 0...1).
    static func rollFloat(in skinRange: ClosedRange<Double> = 0...1) -> Double {
        var roll = Double.random(in: 0..<1)
        var tier = Wear.battleScarred
        for wear in Wear.allCases {
            if roll < wear.tierWeight {
                tier = wear
                break
            }
            roll -= wear.tierWeight
        }
        let raw = Double.random(in: tier.range.lowerBound..<tier.range.upperBound)
        return skinRange.lowerBound + raw * (skinRange.upperBound - skinRange.lowerBound)
    }
}
