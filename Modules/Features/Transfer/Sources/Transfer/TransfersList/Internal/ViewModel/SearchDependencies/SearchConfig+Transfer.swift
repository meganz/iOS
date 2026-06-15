import MEGADesignToken
import Search
import SwiftUI
import UIKit

extension SearchConfig {
    /// `SearchConfig` for the new Transfers screen. The `rowBuilder` closure is
    /// the load-bearing piece: it resolves the per-row VM from the registry by
    /// `ResultId` and constructs `TransferResultRowView`. Non-transfer results
    /// return `nil`, preserving the default node row path for any future
    /// heterogeneous use.
    ///
    /// Chip/row/color assets fall back to `SearchConfig.init`'s shared defaults for
    /// visual parity with other Search-backed screens; the custom `rowBuilder` and
    /// `emptyViewAssetFactory` are the only screen-specific pieces.
    @MainActor
    static func transfers(registry: TransferRegistry) -> SearchConfig {
        .init(
            emptyViewAssetFactory: { _, _ in
                SearchConfig.EmptyViewAssets(
                    image: Image(systemName: "tray"),
                    title: "",
                    titleTextColor: TokenColors.Icon.secondary.swiftUI,
                    actions: []
                )
            },
            rowBuilder: { result in
                guard result.type == .transfer else { return nil }
                guard let vm = registry.rowViewModel(for: result.id) else {
                    return AnyView(EmptyView())
                }
                return AnyView(
                    TransferResultRowView(viewModel: vm)
                        .listRowInsets(EdgeInsets())
                )
            }
        )
    }
}
