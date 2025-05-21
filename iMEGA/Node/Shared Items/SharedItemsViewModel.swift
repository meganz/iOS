import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGASwiftUI
import UIKit

@MainActor
@objc final class SharedItemsViewModel: NSObject, Sendable {

    private let router = SharedItemsViewRouter()
    private let shareUseCase: any ShareUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol
    private let moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    let searchDebouncer = Debouncer(delay: 0.5)
    
    init(shareUseCase: some ShareUseCaseProtocol,
         mediaUseCase: some MediaUseCaseProtocol,
         nodeUseCase: some NodeUseCaseProtocol,
         saveMediaToPhotosUseCase: some SaveMediaToPhotosUseCaseProtocol,
         moveToRubbishBinViewModel: some MoveToRubbishBinViewModelProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.shareUseCase = shareUseCase
        self.mediaUseCase = mediaUseCase
        self.nodeUseCase = nodeUseCase
        self.saveMediaToPhotosUseCase = saveMediaToPhotosUseCase
        self.moveToRubbishBinViewModel = moveToRubbishBinViewModel
        self.featureFlagProvider = featureFlagProvider
    }

    @objc var isSearchByNodetagsEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .searchByNodeTags)
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
        guard isSearchByNodetagsEnabled,
              let searchText,
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
}
