import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGASwiftUI
import Search
import UIKit

@MainActor
protocol SharedItemsViewing: AnyObject {
    var currentSortOrder: MEGADomain.SortOrderEntity { get set }
    var selectedTab: SharedItemsTabSelection { get }
}

@MainActor
@objc final class SharedItemsViewModel: NSObject, Sendable {

    private let router = SharedItemsViewRouter()
    private let shareUseCase: any ShareUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol
    private let moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol

    let searchDebouncer = Debouncer(delay: 0.5)
    private weak var sharedItemsView: (any SharedItemsViewing)?

    private let sortHeaderCoordinator: SearchResultsSortHeaderCoordinator

    var sortHeaderViewModel: SearchResultsHeaderSortViewViewModel {
        sortHeaderCoordinator.headerViewModel
    }

    private var selectedTab: SharedItemsTabSelection {
        sharedItemsView?.selectedTab ?? .incoming
    }

    init(shareUseCase: some ShareUseCaseProtocol,
         mediaUseCase: some MediaUseCaseProtocol,
         nodeUseCase: some NodeUseCaseProtocol,
         saveMediaToPhotosUseCase: some SaveMediaToPhotosUseCaseProtocol,
         moveToRubbishBinViewModel: some MoveToRubbishBinViewModelProtocol,
         sortOptionsViewModel: SearchResultsSortOptionsViewModel,
         sharedItemsView: some SharedItemsViewing
    ) {
        self.shareUseCase = shareUseCase
        self.mediaUseCase = mediaUseCase
        self.nodeUseCase = nodeUseCase
        self.saveMediaToPhotosUseCase = saveMediaToPhotosUseCase
        self.moveToRubbishBinViewModel = moveToRubbishBinViewModel
        self.sharedItemsView = sharedItemsView
        self.sortHeaderCoordinator = .init(
            sortOptionsViewModel: sortOptionsViewModel,
            currentSortOrderProvider: { [weak sharedItemsView] in
                sharedItemsView?.currentSortOrder.toSearchSortOrderEntity() ?? .init(key: .name)
            },
            sortOptionSelectionHandler: { @MainActor [weak sharedItemsView] sortOption in
                sharedItemsView?.currentSortOrder = sortOption.sortOrder.toDomainSortOrderEntity()
            },
            hiddenSortOptionKeysProvider: { [weak sharedItemsView] in
                Self.keysToHide(for: sharedItemsView?.selectedTab ?? .incoming)
            }
        )
    }

    func openShareFolderDialog(forNodes nodes: [MEGANode]) {
        Task { [weak self] in
            do {
                _ = try await self?.shareUseCase.createShareKeys(forNodes: nodes.toNodeEntities())
                self?.router.showShareFoldersContactView(withNodes: nodes)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    @objc func showPendingOutShareModal(for email: String) {
        router.showPendingOutShareModal(for: email)
    }
    
    @objc func areMediaNodes(_ nodes: [MEGANode]) -> Bool {
        guard nodes.isNotEmpty else { return false }
        return nodes.allSatisfy { mediaUseCase.isPlayableMediaFile($0.toNodeEntity()) }
    }
    
    @objc func saveNodesToPhotos(_ nodes: [MEGANode]) async {
        guard areMediaNodes(nodes) else { return }
        
        do {
            try await saveMediaToPhotosUseCase.saveToPhotos(nodes: nodes.toNodeEntities())
        } catch {
            if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                await SVProgressHUD.dismiss()
                SVProgressHUD.show(MEGAAssets.UIImage.saveToPhotos, status: error.localizedDescription)
            }
        }
    }
    
    @objc func moveNodeToRubbishBin(_ node: MEGANode) {
        moveToRubbishBinViewModel.moveToRubbishBin(nodes: [node].toNodeEntities())
    }

    @objc func descriptionForNode(_ node: MEGANode, with searchText: String?) -> NSAttributedString? {
        guard let description = node.description,
              let searchText,
              description.containsIgnoringCaseAndDiacritics(searchText: searchText) else { return nil }
        return node.attributedDescription(searchText: searchText)
    }

    @objc func tagsForNode(_ node: MEGANode, with searchText: String?) -> [NSAttributedString] {
        guard let searchText,
              searchText.isNotEmpty,
              let tags = node.tags?.toStringArray() else { return [] }
        let removedHashTagSearchText = searchText.removingFirstLeadingHash()
        return tags
            .filter { $0.containsIgnoringCaseAndDiacritics(searchText: removedHashTagSearchText) }
            .map {
            ("#" + $0)
                .forceLeftToRight()
                .highlightedStringWithKeyword(
                    removedHashTagSearchText,
                    primaryTextColor: TokenColors.Text.primary,
                    highlightedTextColor: TokenColors.Notifications.notificationSuccess,
                    normalFont: .preferredFont(style: .subheadline, weight: .medium)
                )
        }
    }
    
    func isFileTakenDown(_ nodeHandle: HandleEntity) async -> Bool {
        await nodeUseCase.isFileTakenDown(nodeHandle)
    }

    func updateSortUI() {
        sortHeaderCoordinator.updateSortUI()
    }

    /// The sort option keys that should be hidden for the current shared items tab.
    ///
    /// This is used to filter out sort options that are not relevant to the
    /// selected tab when building `displaySortOptionsViewModel`.
    ///
    /// - For the `.outgoing` tab, the `.linkCreated` sort option is hidden.
    /// - For the `.links` tab, the `.shareCreated` sort option is hidden.
    /// - For the `.incoming`, both `.linkCreated` and .shareCreated` are hidden.
    static func keysToHide(for tab: SharedItemsTabSelection) -> Set<Search.SortOrderEntity.Key> {
        switch tab {
        case .outgoing: [.linkCreated]
        case .links: [.shareCreated]
        default: [.linkCreated, .shareCreated]
        }
    }
}
