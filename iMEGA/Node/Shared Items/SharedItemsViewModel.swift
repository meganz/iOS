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
    private let sortOptionsViewModel: SearchResultsSortOptionsViewModel
    private weak var sharedItemsView: (any SharedItemsViewing)?

    private var currentSortOrder: Search.SortOrderEntity {
        sharedItemsView?.currentSortOrder.toSearchSortOrderEntity() ?? .init(key: .name)
    }

    lazy var sortHeaderViewModel: SearchResultsHeaderSortViewViewModel = {
        let sortOptions = sortOptionsViewModel.sortOptions
        assert(sortOptions.isNotEmpty, "Sort options should not be empty")
        let sortOption = sortOptions
            .first(where: { $0.sortOrder == currentSortOrder }) ?? sortOptions[0]

        return .init(selectedOption: sortOption, displaySortOptionsViewModel: displaySortOptionsViewModel)
    }()

    private var selectedTab: SharedItemsTabSelection {
        sharedItemsView?.selectedTab ?? .incoming
    }

    /// The sort option keys that should be hidden for the current shared items tab.
    ///
    /// This is used to filter out sort options that are not relevant to the
    /// selected tab when building `displaySortOptionsViewModel`.
    ///
    /// - For the `.outgoing` tab, the `.linkCreated` sort option is hidden.
    /// - For the `.links` tab, the `.shareCreated` sort option is hidden.
    /// - For the `.incoming`, both `.linkCreated` and .shareCreated` are hidden.
    var keysToHide: [Search.SortOrderEntity.Key] {
        switch selectedTab {
        case .outgoing: [.linkCreated]
        case .links: [.shareCreated]
        default: [.linkCreated, .shareCreated]
        }
    }

    var displaySortOptionsViewModel: SearchResultsSortOptionsViewModel {
        let currentSearchSortOrder = currentSortOrder
        let keysToHide = self.keysToHide

        let displaySortOptions = sortOptionsViewModel.sortOptions.compactMap { sortOption -> SearchResultsSortOption? in
            guard keysToHide.notContains(sortOption.sortOrder.key) else { return nil }
            guard currentSearchSortOrder != sortOption.sortOrder else { return nil }
            guard currentSearchSortOrder.key != sortOption.sortOrder.key else { return sortOption }
            guard sortOption.sortOrder.direction != .descending else { return nil }
            return sortOption.removeIcon()
        }

        return sortOptionsViewModel.makeNewViewModel(with: displaySortOptions) { [weak self] in
            // Selection is sort option already but it might not contain the icon.
            // So need to get the original sort option which contains the icon.
            guard let self,
                  let selectedSortOption = $0.currentDirectionIcon == nil ? sortOption(for: $0.sortOrder) : $0 else {
                return
            }

            handleSelectedSortOption(selectedSortOption)
        }
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
        self.sortOptionsViewModel = sortOptionsViewModel
        self.sharedItemsView = sharedItemsView
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

    func setSortOrderType(_ sortOrderType: MEGASortOrderType) {
        guard let sortOrderOption = sortOptionsViewModel
            .sortOptions
            .first(where: { $0.sortOrder.toMEGASortOrderType() == sortOrderType }) else {
            return
        }

        handleSelectedSortOption(sortOrderOption)
    }

    func updateSortUI() {
        guard let currentSortOrder = sharedItemsView?.currentSortOrder,
              let sortOption = sortOption(for: currentSortOrder.toSearchSortOrderEntity()) else {
            return
        }
        sortHeaderViewModel.selectionChanged(to: sortOption)
        sortHeaderViewModel.displaySortOptionsViewModel = displaySortOptionsViewModel
    }

    private func sortOption(for sortOrder: Search.SortOrderEntity) -> SearchResultsSortOption? {
        sortOptionsViewModel
            .sortOptions
            .first(where: { $0.sortOrder == sortOrder })
    }

    private func handleSelectedSortOption(_ sortOption: SearchResultsSortOption) {
        sortHeaderViewModel.selectionChanged(to: sortOption)
        sharedItemsView?.currentSortOrder = sortOption.sortOrder.toDomainSortOrderEntity()
        sortHeaderViewModel.displaySortOptionsViewModel = displaySortOptionsViewModel
    }
}
