//
//  WeaponCase.swift
//  CS2 Cases
//

import SwiftUI

struct WeaponCase: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let accentColor: Color
    let imageURLString: String
    let skins: [Skin]

    var imageURL: URL? { URL(string: imageURLString) }

    /// Picks a random skin, respecting real CS2 per-rarity drop odds.
    func rollSkin() -> Skin {
        let tiers = Dictionary(grouping: skins, by: \.rarity)
        let totalWeight = tiers.keys.reduce(0) { $0 + $1.weight }
        var roll = Double.random(in: 0..<totalWeight)
        for rarity in Rarity.allCases {
            guard let pool = tiers[rarity], !pool.isEmpty else { continue }
            if roll < rarity.weight {
                return pool.randomElement()!
            }
            roll -= rarity.weight
        }
        return skins.randomElement()!
    }
}
