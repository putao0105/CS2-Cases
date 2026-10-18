//
//  Rarity.swift
//  CS2 Cases
//

import SwiftUI

enum Rarity: Int, CaseIterable, Comparable, Codable {
    case milSpec
    case restricted
    case classified
    case covert
    case special

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .milSpec: return "Mil-Spec"
        case .restricted: return "Restricted"
        case .classified: return "Classified"
        case .covert: return "Covert"
        case .special: return "Extraordinary"
        }
    }

    /// Exact CS:GO/CS2 rarity colors (matches the game's own palette,
    /// not an approximation).
    var color: Color {
        switch self {
        case .milSpec: return Color(red: 0x4b / 255, green: 0x69 / 255, blue: 0xff / 255)
        case .restricted: return Color(red: 0x88 / 255, green: 0x47 / 255, blue: 0xff / 255)
        case .classified: return Color(red: 0xd3 / 255, green: 0x2e / 255, blue: 0xe6 / 255)
        case .covert: return Color(red: 0xeb / 255, green: 0x4b / 255, blue: 0x4b / 255)
        // The real game's "Rare Special Item" (knife/glove) gold.
        case .special: return Color(red: 0xe4 / 255, green: 0xae / 255, blue: 0x39 / 255)
        }
    }

    /// Official drop odds within a case.
    var weight: Double {
        switch self {
        case .milSpec: return 79.92
        case .restricted: return 15.98
        case .classified: return 3.20
        case .covert: return 0.64
        case .special: return 0.26
        }
    }
}
