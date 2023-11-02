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
    
    @Published var thumbnailImage: UIImage = UIImage()

    @Published var properties: [UIImage] = []

    @Published var isDownloadHidden: Bool = true

    var title: String {
        result.title
    }
    var id: String {
        result.id.description
    }

    var subtitle: String {
        result.description
    }
    
    var selectedCheckmarkImage: UIImage {
        rowAssets.itemSelected
    }
    var unselectedCheckmarkImage: UIImage {
        rowAssets.itemUnselected
    }

    var thumbnailInfo: SearchResultThumbnailInfo {
        result.thumbnailPreviewInfo
    }

    let result: SearchResult

    let contextButtonImage: UIImage
    let playImage: UIImage
    let downloadedImage: UIImage
    let moreList: UIImage
    let moreGrid: UIImage

    let colorAssets: SearchConfig.ColorAssets
    let previewContent: PreviewContent
    let actions: UserActions
    let rowAssets: SearchConfig.RowAssets

    init(
        with result: SearchResult,
        rowAssets: SearchConfig.RowAssets,
        colorAssets: SearchConfig.ColorAssets,
        previewContent: PreviewContent,
        actions: UserActions
    ) {
        self.result = result

        self.contextButtonImage = rowAssets.contextImage
        self.playImage = rowAssets.playImage
        self.downloadedImage = rowAssets.downloadedImage
        self.moreList = rowAssets.moreList
        self.moreGrid = rowAssets.moreGrid

        self.colorAssets = colorAssets
        self.previewContent = previewContent
        self.actions = actions
        self.rowAssets = rowAssets
    }

    @MainActor
    func loadThumbnail() async {
        let data = await result.thumbnailImageData()
        
        if let image = UIImage(data: data) {
            self.thumbnailImage = image
        }
    }

    @MainActor
    func loadProperties() async {
        properties = await thumbnailInfo.propertiesData()
    }

    @MainActor
    func chekDownloadVisibility() async {
        isDownloadHidden = await thumbnailInfo.downloadVisibilityData()
    }
}
