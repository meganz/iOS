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
        nodeUseCase: some NodeUseCaseProtocol,
        isDesignTokenEnabled: Bool = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
    ) {
        self.navigationController = navigationController
        self.nodeUseCase = nodeUseCase
        self.isDesignTokenEnabled = isDesignTokenEnabled
        self.titleTextColor = { colorScheme in
            guard isDesignTokenEnabled else {
                return colorScheme == .light ? UIColor.gray515151.swiftUI : UIColor.grayD1D1D1.swiftUI
            }

            return TokenColors.Icon.secondary.swiftUI
        }
    }

    func defaultAsset(for nodeSource: NodeSource, config: NodeBrowserConfig) -> SearchConfig.EmptyViewAssets {
        let emptyViewAssets: SearchConfig.EmptyViewAssets

        switch nodeSource {
        case .node(let parentNodeProvider):
            emptyViewAssets = defaultAsset(forParentNodeProvider: parentNodeProvider, config: config)
        case .recentActionBucket:
            emptyViewAssets = defaultAssetForRecentActionBucket()
        }

        return emptyViewAssets
    }

    // MARK: - Private methods.

    private func defaultAsset(
        forParentNodeProvider parentNodeProvider: ParentNodeProvider,
        config: NodeBrowserConfig
    ) -> SearchConfig.EmptyViewAssets {
        let emptyViewAssets: SearchConfig.EmptyViewAssets

        if let parentNode = parentNodeProvider() {
            emptyViewAssets = defaultAsset(forParentNode: parentNode, config: config)
        } else {
            emptyViewAssets = defaultAssetForEmptyFolder()
        }

        return emptyViewAssets
    }

    private func defaultAsset(
        forParentNode parentNode: NodeEntity,
        config: NodeBrowserConfig
    ) -> SearchConfig.EmptyViewAssets {
        let emptyViewAssets: SearchConfig.EmptyViewAssets

        switch config.displayMode {
        case .cloudDrive where parentNode.nodeType == .root:
            emptyViewAssets = defaultAssetForCloudDriveRootFolder(parentNode: parentNode)
        case .rubbishBin where nodeUseCase.isARubbishBinRootNode(nodeHandle: parentNode.handle):
            emptyViewAssets = defaultAssetForRubbishBinRootFolder()
        default:
            emptyViewAssets = defaultAssetForEmptyFolder(for: config.displayMode != .rubbishBin ? parentNode : nil)
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

    private func defaultAssetForRecentActionBucket() -> SearchConfig.EmptyViewAssets {
        .init(
            image: Image(.searchEmptyState),
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            titleTextColor: titleTextColor
        )
    }

    private func defaultAssetForEmptyFolder(for parentNode: NodeEntity? = nil) -> SearchConfig.EmptyViewAssets {
        .init(
            image: Image(.folderEmptyState),
            title: Strings.Localizable.emptyFolder,
            titleTextColor: titleTextColor,
            actions: makeDefaultActions(for: parentNode)
        )
    }

    private func makeDefaultActions(for parentNode: NodeEntity?) -> [SearchConfig.EmptyViewAssets.Action] {
        guard let parentNode else {
            return []
        }

        let actions: [SearchConfig.EmptyViewAssets.Action]
        let access = nodeUseCase.nodeAccessLevel(nodeHandle: parentNode.handle)

        switch access {
        case .read, .unknown:
            actions = []
        case .readWrite, .full, .owner:
            actions = [addFilesAction(for: parentNode)]
        }

        return actions
    }

    private func addFilesAction(for nodeEntity: NodeEntity) -> SearchConfig.EmptyViewAssets.Action {
        .init(
            title: Strings.Localizable.addFiles,
            backgroundColor: { colorScheme in
                guard isDesignTokenEnabled else {
                    return colorScheme == .light ? UIColor.green00A886.swiftUI : UIColor.green00C29A.swiftUI
                }

                return TokenColors.Support.success.swiftUI
            },
            menu: menu(for: nodeEntity)
        )
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
