import ChatRepo
import Foundation
import Home
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPreference
import MEGARepo
import MEGASwift
import MEGASwiftUI
import MEGAUI
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI

@MainActor
final class HomeScreenFactory: NSObject {
    
     var sdk: MEGASdk {
        MEGASdk.sharedSdk
    }
    
    var megaStore: MEGAStore {
        MEGAStore.shareInstance()
    }
    
    func createHomeScreen(
        from tabBarController: MainTabBarController
    ) -> UIViewController {
        createRevampedHomeScreen(
            from: tabBarController
        )
    }

    private func makeNodeIconUsecase() -> some NodeIconUsecaseProtocol {
        NodeIconUseCase(nodeIconRepo: NodeAssetsManager.shared)
    }

    private func makeDownloadedNodesListener() -> some DownloadedNodesListening {
        CloudDriveDownloadedNodesListener(
            subListeners: [
                CloudDriveDownloadTransfersListener(
                    sdk: sdk,
                    transfersListenerUsecase: TransfersListenerUseCase(
                        repo: TransfersListenerRepository.newRepo,
                        preferenceUseCase: PreferenceUseCase.default
                    ),
                fileSystemRepo: FileSystemRepository.sharedRepo
            ),
            NodesSavedToOfflineListener(notificationCenter: .default)
        ]
        )
    }

    func nodeActionListener(_ tracker: any AnalyticsTracking) -> (MegaNodeActionType?, [MEGANode]) -> Void {
        { action, _ in
            switch action {
            case .saveToPhotos:
                tracker.trackAnalyticsEvent(with: SearchResultSaveToDeviceMenuItemEvent())
            case .manageLink, .shareLink:
                tracker.trackAnalyticsEvent(with: SearchResultShareMenuItemEvent())
            case .hide:
                tracker.trackAnalyticsEvent(with: HideNodeMenuItemEvent())
            default:
                {}() // we do not track other events here yet
            }
        }
    }
    
    func makeRouter(
        navController: UINavigationController,
        tracker: some AnalyticsTracking
    ) -> some NodeRouting {
        HomeSearchResultRouter(
            navigationController: navController,
            nodeActionViewControllerDelegate: NodeActionViewControllerGenericDelegate(
                viewController: navController,
                moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: navController),
                nodeActionListener: nodeActionListener(tracker)
            ),
            backupsUseCase: makeBackupsUseCase(),
            nodeUseCase: makeNodeUseCase()
        )
    }
    
    func makeBackupsUseCase() -> some BackupsUseCaseProtocol {
         BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
         )
    }

    func makeResultsProvider(
        parentNodeProvider: @escaping () -> NodeEntity?,
        navigationController: UINavigationController,
        isFromSharedItem: Bool = false
    ) -> HomeSearchResultsProvider {
        let nodeUseCase = makeNodeUseCase()
        let mapper = SearchResultMapper(
            sdk: sdk,
            nodeIconUsecase: makeNodeIconUsecase(),
            nodeDetailUseCase: makeNodeDetailUseCase(),
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: makeSensitiveNodeUseCase(),
            mediaUseCase: makeMediaUseCase(),
            nodeActions: .makeActions(sdk: sdk, navigationController: navigationController),
            showHiddenNodeBlur: !isFromSharedItem
        )
        
        return HomeSearchResultsProvider(
            parentNodeProvider: parentNodeProvider,
            filesSearchUseCase: makeFilesSearchUseCase(),
            nodeUseCase: makeNodeUseCase(),
            downloadedNodesListener: makeDownloadedNodesListener(),
            sensitiveDisplayPreferenceUseCase: makeSensitiveDisplayPreferenceUseCase(),
            resultsMapper: mapper,
            resultsUpdates: CloudDriveResultsUpdatesProvider(nodeUseCase: nodeUseCase),
            allChips: Self.allChips(),
            sdk: sdk,
            isFromSharedItem: isFromSharedItem
        )
    }
    private static func allChips() -> [SearchChipEntity] {
        SearchChipEntity.allChips(
            currentDate: { .init() },
            calendar: .autoupdatingCurrent
        )
    }
    
    var notificationCenter: NotificationCenter {
        .default
    }
    
    func makeNodeDetailUseCase() -> some NodeDetailUseCaseProtocol {
        NodeDetailUseCase(
            sdkNodeClient: .live,
            nodeThumbnailHomeUseCase: NodeThumbnailHomeUseCase(
                sdkNodeClient: .live,
                fileSystemClient: .live,
                thumbnailRepo: ThumbnailRepository.newRepo
            )
        )
    }
    
    private func makeFilesSearchUseCase() -> some FilesSearchUseCaseProtocol {
        FilesSearchUseCase(
            repo: FilesSearchRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    func makeNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    func makeMediaUseCase() -> some MediaUseCaseProtocol {
        MediaUseCase(
            fileSearchRepo: FilesSearchRepository.newRepo,
            videoMediaUseCase: VideoMediaUseCase(videoMediaRepository: VideoMediaRepository.newRepo)
        )
    }
    
    func makeSensitiveNodeUseCase() -> some SensitiveNodeUseCaseProtocol {
        SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo)
        )
    }
    
    func makeSensitiveDisplayPreferenceUseCase() -> some SensitiveDisplayPreferenceUseCaseProtocol {
        SensitiveDisplayPreferenceUseCase(
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo))
    }
}
