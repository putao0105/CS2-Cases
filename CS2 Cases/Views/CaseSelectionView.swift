//
//  CaseSelectionView.swift
//  CS2 Cases
//

import SwiftUI

struct CaseSelectionView: View {
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 4) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(CaseData.allCases) { weaponCase in
                        NavigationLink(value: weaponCase) {
                            CaseTileView(weaponCase: weaponCase)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
            .padding()
        }
        .background(CSBackground(dim: 0.35).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle("CS2 Cases")
        .navigationDestination(for: WeaponCase.self) { weaponCase in
            CaseOpeningView(caseItem: weaponCase)
        }
    }
}

/// A rounded glass bubble holding the case art, faintly tinted with the
/// case's accent color.
private struct CaseTileView: View {
    let weaponCase: WeaponCase

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: weaponCase.imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(.white)
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.3))
                @unknown default:
                    EmptyView()
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 8, y: 6)
            .frame(height: 96)

            HStack(spacing: 6) {
                Circle()
                    .fill(weaponCase.accentColor)
                    .frame(width: 8, height: 8)
                Text(weaponCase.name)
                    .font(.cs(16, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .contentShape(.rect(cornerRadius: 28))
        .glassEffect(.regular.tint(weaponCase.accentColor.opacity(0.12)).interactive(), in: .rect(cornerRadius: 28))
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack {
        CaseSelectionView()
    }
    .environment(InventoryStore())
}
