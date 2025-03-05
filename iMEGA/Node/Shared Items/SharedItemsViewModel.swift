import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import UIKit

@MainActor
@objc final class SharedItemsViewModel: NSObject, Sendable {

    private let router = SharedItemsViewRouter()
    private let shareUseCase: any ShareUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol
    private let moveToRubbishBinViewModel: any MoveToRubbishBinViewModelProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol

    let searchDebouncer = Debouncer(delay: 0.5)
    
    init(shareUseCase: some ShareUseCaseProtocol,
         mediaUseCase: some MediaUseCaseProtocol,
         saveMediaToPhotosUseCase: some SaveMediaToPhotosUseCaseProtocol,
         moveToRubbishBinViewModel: some MoveToRubbishBinViewModelProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.shareUseCase = shareUseCase
        self.mediaUseCase = mediaUseCase
        self.saveMediaToPhotosUseCase = saveMediaToPhotosUseCase
        self.moveToRubbishBinViewModel = moveToRubbishBinViewModel
        self.featureFlagProvider = featureFlagProvider
    }

    func openShareFolderDialog(forNodes nodes: [MEGANode]) {
        Task {
            do {
                _ = try await shareUseCase.createShareKeys(forNodes: nodes.toNodeEntities())
                router.showShareFoldersContactView(withNodes: nodes)
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
                SVProgressHUD.show(UIImage.saveToPhotos, status: error.localizedDescription)
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
        guard featureFlagProvider.isFeatureFlagEnabled(for: .searchByNodeTags),
              let searchText,
              searchText.isNotEmpty,
              let tags = node.tags?.toStringArray() else { return [] }
        let removedHashTagSearchText = searchText.removingFirstLeadingHash()
        return tags.map {
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
}
