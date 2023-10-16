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

final class SearchResultRowViewModel: ObservableObject, Identifiable, Equatable {
    
    static func == (lhs: SearchResultRowViewModel, rhs: SearchResultRowViewModel) -> Bool {
        rhs.result == lhs.result
    }
    
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

    let result: SearchResult
    let contextButtonImage: UIImage
    let previewContent: PreviewContent
    let actions: UserActions
    
    init(
        with result: SearchResult,
        contextButtonImage: UIImage,
        previewContent: PreviewContent,
        actions: UserActions
    ) {
        self.result = result
        self.contextButtonImage = contextButtonImage
        self.previewContent = previewContent
        self.actions = actions
    }
    
    @MainActor
    func loadThumbnail() async {
        let data = await result.thumbnailImageData()
        if let image = UIImage(data: data) {
            thumbnailImage = image
        }
    }
    
}
