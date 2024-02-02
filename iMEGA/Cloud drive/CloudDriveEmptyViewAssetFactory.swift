import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import Search
import SwiftUI
import UIKit

struct CloudDriveEmptyViewAssetFactory {
    private let navigationController: UINavigationController
    private let nodeUseCase: any NodeUseCaseProtocol
    private let isDesignTokenEnabled: Bool
    private let titleTextColor: (ColorScheme) -> Color

    init(
        navigationController: UINavigationController,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.navigationController = navigationController
        self.nodeUseCase = nodeUseCase
        let isDesignTokenEnabled = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
        self.isDesignTokenEnabled = isDesignTokenEnabled
        self.titleTextColor = { colorScheme in
            guard isDesignTokenEnabled else {
                return colorScheme == .light ? UIColor.gray515151.swiftUI : UIColor.grayD1D1D1.swiftUI
            }

            return TokenColors.Icon.secondary.swiftUI
        }
    }

    func defaultAsset(for nodeSource: NodeSource) -> SearchConfig.EmptyViewAssets {
        let emptyViewAssets: SearchConfig.EmptyViewAssets

        switch nodeSource {
        case .node(let parentNodeProvider):
            emptyViewAssets = defaultAsset(forParentNodeProvider: parentNodeProvider)
        case .recentActionBucket:
            emptyViewAssets = defaultAssetForRecentActionBucket()
        }

        return emptyViewAssets
    }

    // MARK: - Private methods.

    private func defaultAsset(
        forParentNodeProvider parentNodeProvider: ParentNodeProvider
    ) -> SearchConfig.EmptyViewAssets {
        let emptyViewAssets: SearchConfig.EmptyViewAssets

        if let parentNode = parentNodeProvider(),
            let asset = defaultAsset(forParentNode: parentNode) {
            emptyViewAssets = asset
        } else {
            emptyViewAssets = emptyFolderStateWithAddFilesOption(parentNodeProvider: parentNodeProvider)
        }

        return emptyViewAssets
    }

    private func defaultAsset(
        forParentNode parentNode: NodeEntity
    ) -> SearchConfig.EmptyViewAssets? {
        let emptyViewAssets: SearchConfig.EmptyViewAssets?

        if nodeUseCase.isARubbishBinRootNode(nodeHandle: parentNode.handle) {
            emptyViewAssets = defaultAssetForRubbishBinRootFolder()
        } else if parentNode.parentHandle == .invalid {
            emptyViewAssets = defaultAssetForCloudDriveRootFolder(parentNode: parentNode)
        } else if nodeUseCase.isInRubbishBin(nodeHandle: parentNode.handle) {
            emptyViewAssets = defaultAssetForNodeInRubbishBinFolder()
        } else {
            emptyViewAssets = nil
        }

        return emptyViewAssets
    }

    private func defaultAssetForCloudDriveRootFolder(parentNode: NodeEntity) -> SearchConfig.EmptyViewAssets {
        .init(
            image: Image(.cloudEmptyState),
            title: Strings.Localizable.cloudDriveEmptyStateTitle,
            titleTextColor: titleTextColor,
            actions: makeDefaultActions(for: parentNode)
        )
    }

    private func defaultAssetForRubbishBinRootFolder() -> SearchConfig.EmptyViewAssets {
        .init(
            image: Image(.folderEmptyState),
            title: Strings.Localizable.cloudDriveEmptyStateTitleRubbishBin,
            titleTextColor: titleTextColor
        )
    }

    private func defaultAssetForNodeInRubbishBinFolder() -> SearchConfig.EmptyViewAssets {
        .init(
            image: Image(.folderEmptyState),
            title: Strings.Localizable.emptyFolder,
            titleTextColor: titleTextColor
        )
    }

    private func defaultAssetForRecentActionBucket() -> SearchConfig.EmptyViewAssets {
        .init(
            image: Image(.searchEmptyState),
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            titleTextColor: titleTextColor
        )
    }

    private func emptyFolderStateWithAddFilesOption(
        parentNodeProvider: ParentNodeProvider
    ) -> SearchConfig.EmptyViewAssets {
        .init(
            image: Image(.folderEmptyState),
            title: Strings.Localizable.emptyFolder,
            titleTextColor: titleTextColor,
            actions: makeDefaultActions(for: parentNodeProvider())
        )
    }

    private func makeDefaultActions(for nodeEntity: NodeEntity?) -> [SearchConfig.EmptyViewAssets.Action] {
        guard let nodeEntity else {
            MEGALogError("node passed to default action is empty")
            return []
        }

        let action = SearchConfig.EmptyViewAssets.Action(
            title: Strings.Localizable.addFiles,
            backgroundColor: { colorScheme in
                guard isDesignTokenEnabled else {
                    return colorScheme == .light ? UIColor.green00A886.swiftUI : UIColor.green00C29A.swiftUI
                }

                return TokenColors.Support.success.swiftUI
            },
            menu: menu(for: nodeEntity)
        )
        return [action]
    }

    private func menu(for nodeEntity: NodeEntity) -> [SearchConfig.EmptyViewAssets.MenuOption] {
        [
            createTextFileMenuOption(for: nodeEntity),
            createNewFolderMenuOption(for: nodeEntity),
            scanDocumentMenuOption(for: nodeEntity),
            importFromFilesMenuOption(for: nodeEntity),
            capturePhotoVideoMenuOption(for: nodeEntity),
            choosePhotoVideoMenuOption(for: nodeEntity)
        ]
    }

    private func createTextFileMenuOption(for nodeEntity: NodeEntity) -> SearchConfig.EmptyViewAssets.MenuOption {
        .init(title: Strings.Localizable.newTextFile, image: Image(.textfile)) {
            createTextFileAlert(for: nodeEntity)
        }
    }

    private func createNewFolderMenuOption(for nodeEntity: NodeEntity) -> SearchConfig.EmptyViewAssets.MenuOption {
        .init(title: Strings.Localizable.newFolder, image: Image(.newFolder)) {
            createNewFolder(for: nodeEntity)
        }
    }

    private func scanDocumentMenuOption(for nodeEntity: NodeEntity) -> SearchConfig.EmptyViewAssets.MenuOption {
        .init(title: Strings.Localizable.scanDocument, image: Image(.scanDocument)) {
            scanDocument(for: nodeEntity)
        }
    }

    private func importFromFilesMenuOption(for nodeEntity: NodeEntity) -> SearchConfig.EmptyViewAssets.MenuOption {
        .init(title: Strings.Localizable.CloudDrive.Upload.importFromFiles, image: Image(.import)) {
            importFromFiles(for: nodeEntity)
        }
    }

    private func capturePhotoVideoMenuOption(for nodeEntity: NodeEntity) -> SearchConfig.EmptyViewAssets.MenuOption {
        .init(title: Strings.Localizable.capturePhotoVideo, image: Image(.capture)) {
            capturePhotoVideo(for: nodeEntity)
        }
    }

    private func choosePhotoVideoMenuOption(for nodeEntity: NodeEntity) -> SearchConfig.EmptyViewAssets.MenuOption {
        .init(title: Strings.Localizable.choosePhotoVideo, image: Image(.saveToPhotos)) {
            choosePhotoVideo(for: nodeEntity)
        }
    }

    private func createTextFileAlert(for nodeEntity: NodeEntity) {
        // Create a text file
    }

    private func createNewFolder(for nodeEntity: NodeEntity) {
        // create a folder
    }

    private func scanDocument(for nodeEntity: NodeEntity) {
        // scan document
    }

    private func importFromFiles(for nodeEntity: NodeEntity) {
        // import files
    }

    private func capturePhotoVideo(for nodeEntity: NodeEntity) {
        // capture photos
    }

    private func choosePhotoVideo(for nodeEntity: NodeEntity) {
        // choose photo or video
    }
}
