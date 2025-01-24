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

@MainActor
class SearchResultRowViewModel: Identifiable, ObservableObject {
    @Published var thumbnailImage: UIImage = UIImage()
    
    /// Specify whether  thumbnailImage was successfully loaded once
    /// This property is needed to animate the thumbnailImage when it is first loaded.
    @Published var isThumbnailLoadedOnce = false

    var title: AttributedString {
        let title = result.title.forceLeftToRight()
        guard let query = query() else {
            return AttributedString(title)
        }

        return AttributedString(
            title.highlightedStringWithKeyword(
                query,
                primaryTextColor: UIColor(titleTextColor),
                highlightedTextColor: UIColor(colorAssets.textHighlightColor)
            )
        )
    }

    var note: String? {
        if let nodeDescription = result.note,
            let query = query(),
           nodeDescription.containsIgnoringCaseAndDiacritics(searchText: query) {
            nodeDescription
        } else {
            nil
        }
    }

    var accessibilityIdentifier: String {
        result.title
    }

    var isSensitive: Bool {
        result.isSensitive
    }
    
    var hasThumbnail: Bool {
        result.hasThumbnail
    }
    
    private lazy var hasVibrantTitle = result.properties.first { $0.vibrancyEnabled } != nil
    
    var titleTextColor: Color {
        hasVibrantTitle ? colorAssets.vibrantColor : colorAssets.titleTextColor
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

    /// A closure that provides the current search text used as a query.
    ///
    /// The `query` property is a function that, when called, returns an optional `String` representing the user's current search input.
    /// It is used to highlight relevant content in note.
    ///
    /// - Returns: A `String?` containing the search query if available, or `nil` if no query is set.
    let query: () -> String?

    let colorAssets: SearchConfig.ColorAssets
    let previewContent: PreviewContent
    let actions: UserActions
    let rowAssets: SearchConfig.RowAssets
    let swipeActions: [SearchResultSwipeAction]

    init(
        result: SearchResult,
        query: @escaping () -> String?,
        rowAssets: SearchConfig.RowAssets,
        colorAssets: SearchConfig.ColorAssets,
        previewContent: PreviewContent,
        actions: UserActions,
        swipeActions: [SearchResultSwipeAction]
    ) {
        self.result = result
        self.query = query
        self.colorAssets = colorAssets
        self.previewContent = previewContent
        self.actions = actions
        self.rowAssets = rowAssets
        self.swipeActions = swipeActions
    }

    func loadThumbnail() async {
        guard !Task.isCancelled else { return }
        let data = await result.thumbnailImageData()
        
        guard !Task.isCancelled else { return }
        guard let image = UIImage(data: data) else { return }
        
        update(thumbnailImage: image)
    }

    func reload(with result: SearchResult) async {
        guard !Task.isCancelled else { return }
        self.result = result
        await loadThumbnail()
    }
    
    private func update(thumbnailImage: UIImage) {
        self.thumbnailImage = thumbnailImage
        if !isThumbnailLoadedOnce {
            isThumbnailLoadedOnce = true
        }
    }
}
