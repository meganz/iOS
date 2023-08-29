import SwiftUI

final class SearchResultsRowViewModel: ObservableObject {
    @Published var thumbnailImage: UIImage?

    var title: String {
        result.title
    }

    var subtitle: String {
        result.description
    }

    private let result: SearchResult

    init(
        with result: SearchResult
    ) {
        self.result = result
    }

    private func loadThumbnail() {
        Task { @MainActor in
           let data = await result.thumbnailImageData()
           thumbnailImage = UIImage(data: data)
        }
    }
}
