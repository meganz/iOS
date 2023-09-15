import SwiftUI
import UIKit

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

    private let result: SearchResult
    let contextButtonImage: UIImage
    let contextAction: (UIButton) -> Void
    let selectionAction: () -> Void

    init(
        with result: SearchResult,
        contextButtonImage: UIImage,
        contextAction: @escaping (UIButton) -> Void,
        selectionAction: @escaping () -> Void
    ) {
        self.result = result
        self.contextAction = contextAction
        self.selectionAction = selectionAction
        self.contextButtonImage = contextButtonImage
    }
    
    @MainActor
    func loadThumbnail() async {
        let data = await result.thumbnailImageData()
        if let image = UIImage(data: data) {
            thumbnailImage = image
        }
    }
    
}
