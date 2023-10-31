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

    let result: SearchResult
    let contextButtonImage: UIImage
    let previewContent: PreviewContent
    let actions: UserActions
    let rowAssets: SearchConfig.RowAssets
    
    init(
        with result: SearchResult,
        contextButtonImage: UIImage,
        previewContent: PreviewContent,
        actions: UserActions,
        rowAssets: SearchConfig.RowAssets
    ) {
        self.result = result
        self.contextButtonImage = contextButtonImage
        self.previewContent = previewContent
        self.actions = actions
        self.rowAssets = rowAssets
    }
    
    @MainActor
    func loadThumbnail() async {
        let data = await result.thumbnailImageData()
        
        if let image = UIImage(data: data) {
            thumbnailImage = image
        }
    }
    
}
