//
//  InventoryStore.swift
//  CS2 Cases
//

import Foundation
import Observation

@Observable
final class InventoryStore {
    private(set) var unboxedSkins: [Skin] = []

    private let defaultsKey = "unboxedSkins"

    init() {
        load()
    }

    func add(_ skin: Skin) {
        // Each unboxed copy gets its own id -- otherwise unboxing the same
        // skin twice yields duplicate ids, which breaks ForEach in the grid.
        unboxedSkins.insert(skin.newCopy(), at: 0)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([Skin].self, from: data) else { return }
        // Older saves may already contain duplicate ids; re-key on load.
        unboxedSkins = decoded.map { $0.newCopy() }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(unboxedSkins) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
