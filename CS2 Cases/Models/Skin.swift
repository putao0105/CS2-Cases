//
//  Skin.swift
//  CS2 Cases
//

import Foundation

struct Skin: Identifiable, Hashable, Codable {
    let id: UUID
    /// Raw CS2 item name, e.g. "AK-47 | Legion of Anubis" or "★ Nomad Knife".
    let name: String
    let rarity: Rarity
    /// Real skin image hosted on Steam's public CDN, loaded at runtime (not bundled).
    let imageURLString: String
    /// Wear float of an unboxed copy. Catalog entries have none, and neither
    /// do items saved before floats existed (optional, so old saves decode).
    var floatValue: Double?

    init(id: UUID = UUID(), name: String, rarity: Rarity, imageURLString: String, floatValue: Double? = nil) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.imageURLString = imageURLString
        self.floatValue = floatValue
    }

    /// The same skin with a fresh identity, for a distinct inventory entry.
    func newCopy() -> Skin {
        Skin(name: name, rarity: rarity, imageURLString: imageURLString, floatValue: floatValue)
    }

    /// An unboxed copy of this catalog skin with a freshly rolled float.
    func unboxed() -> Skin {
        Skin(name: name, rarity: rarity, imageURLString: imageURLString, floatValue: Wear.rollFloat())
    }

    var wear: Wear? { floatValue.map(Wear.init(float:)) }

    /// The float as the game shows it, e.g. "0.183746219".
    var formattedFloat: String? {
        floatValue.map { String(format: "%.9f", $0) }
    }

    private var nameParts: [String] { name.components(separatedBy: " | ") }
    /// Weapon part of the name, without the "★ " prefix knives/gloves carry.
    var weaponName: String {
        let weapon = nameParts.first ?? name
        return weapon.hasPrefix("★ ") ? String(weapon.dropFirst(2)) : weapon
    }
    var skinName: String { nameParts.count > 1 ? nameParts[1] : "Vanilla" }
    var imageURL: URL? { URL(string: imageURLString) }
}
