import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import Search
import SwiftUI

@MainActor
struct CloudDriveEmptyViewAssetFactory {
    private let nodeUseCase: any NodeUseCaseProtocol
    private let titleTextColor: Color

    init(nodeUseCase: some NodeUseCaseProtocol) {
        self.nodeUseCase = nodeUseCase
        self.titleTextColor = TokenColors.Text.primary.swiftUI
    }

    func defaultAsset(for nodeSource: NodeSource, config: NodeBrowserConfig) -> SearchConfig.EmptyViewAssets {
        switch nodeSource {
        case .node(let parentNodeProvider):
            defaultAsset(forParentNodeProvider: parentNodeProvider, config: config)
        case .recentActionBucket:
            defaultAssetForRecentActionBucket()
        }
    }

    // MARK: - Private methods.

    private func defaultAsset(
        forParentNodeProvider parentNodeProvider: ParentNodeProvider,
        config: NodeBrowserConfig
    ) -> SearchConfig.EmptyViewAssets {
        if let parentNode = parentNodeProvider() {
            defaultAsset(forParentNode: parentNode, config: config)
        } else {
            defaultAssetForEmptyFolder()
        }
    }

    private func defaultAsset(
        forParentNode parentNode: NodeEntity,
        config: NodeBrowserConfig
    ) -> SearchConfig.EmptyViewAssets {
        switch config.displayMode {
        case .cloudDrive where parentNode.nodeType == .root:
            defaultAssetForCloudDriveRootFolder()
        case .rubbishBin where nodeUseCase.isARubbishBinRootNode(nodeHandle: parentNode.handle):
            defaultAssetForRubbishBinRootFolder()
        default:
            defaultAssetForEmptyFolder()
        }
    }

    private func defaultAssetForCloudDriveRootFolder() -> SearchConfig.EmptyViewAssets {
        .init(
            image: MEGAAssets.Image.glassCloud,
            title: Strings.Localizable.cloudDriveEmptyStateTitle,
            titleTextColor: titleTextColor
        )
    }

    private func defaultAssetForRubbishBinRootFolder() -> SearchConfig.EmptyViewAssets {
        .init(
            image: MEGAAssets.Image.glassTrash,
            title: Strings.Localizable.cloudDriveEmptyStateTitleRubbishBin,
            titleTextColor: titleTextColor
        )
    }

    private func defaultAssetForRecentActionBucket() -> SearchConfig.EmptyViewAssets {
        .init(
            image: MEGAAssets.Image.glassSearch02,
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            titleTextColor: titleTextColor
        )
    }

    private func defaultAssetForEmptyFolder() -> SearchConfig.EmptyViewAssets {
        .init(
            image: MEGAAssets.Image.glassFolder,
            title: Strings.Localizable.emptyFolder,
            titleTextColor: titleTextColor
        )
    }
}
