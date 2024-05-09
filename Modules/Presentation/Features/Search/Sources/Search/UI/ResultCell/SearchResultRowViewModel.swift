import MEGAPresentation
import MEGASwiftUI
import SwiftUI
import UIKit

extension SearchResultRowViewModel {
    struct UserActions {
        /// ellipsis menu button was tapped
        let contextAction: (UIButton) -> Void
        /// result was selected
        let selectionAction: () -> Void
        /// result was previewed with long pressed and then tapped
        let previewTapAction: () -> Void
    }
}

class SearchResultRowViewModel: Identifiable, ObservableObject {
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    @Published var thumbnailImage: UIImage = UIImage()

    var title: String {
        result.title
    }
    
    var isSensitive: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) && result.isSensitive
    }
    
    var hasThumbnail: Bool {
        result.hasThumbnail
    }
    
    var hasVibrantTitle: Bool {
        result.properties.first { $0.vibrancyEnabled } != nil
    }
    
    var id: String {
        result.id.description
    }
    
    var selectedCheckmarkImage: UIImage {
        rowAssets.itemSelected
    }
    
    var unselectedCheckmarkImage: UIImage {
        rowAssets.itemUnselected
    }

    var contextButtonImage: UIImage {
        rowAssets.contextImage
    }
    
    var playImage: UIImage {
        rowAssets.playImage
    }
    
    var downloadedImage: UIImage {
        rowAssets.downloadedImage
    }
    
    var moreList: UIImage {
        rowAssets.moreList
    }
    
    var moreGrid: UIImage {
        rowAssets.moreGrid
    }

    var result: SearchResult
    
    let colorAssets: SearchConfig.ColorAssets
    let previewContent: PreviewContent
    let actions: UserActions
    let rowAssets: SearchConfig.RowAssets
    let swipeActions: [SearchResultSwipeAction]

    init(
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        result: SearchResult,
        rowAssets: SearchConfig.RowAssets,
        colorAssets: SearchConfig.ColorAssets,
        previewContent: PreviewContent,
        actions: UserActions,
        swipeActions: [SearchResultSwipeAction]
    ) {
        self.featureFlagProvider = featureFlagProvider
        self.result = result
        self.colorAssets = colorAssets
        self.previewContent = previewContent
        self.actions = actions
        self.rowAssets = rowAssets
        self.swipeActions = swipeActions
    }

    @MainActor
    func loadThumbnail() async {
        let data = await result.thumbnailImageData()
        if let image = UIImage(data: data) {
            self.thumbnailImage = image
        }
    }

    @MainActor
    func reload(with result: SearchResult) async {
        self.result = result
        await loadThumbnail()
    }
}

extension SearchResultRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SearchResultRowViewModel, rhs: SearchResultRowViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
