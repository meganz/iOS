import MEGAAppPresentation
import MEGASwift
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

    var plainTitle: String {
        result.title.forceLeftToRight()
    }

    var attributedTitle: AttributedString {
        guard let query = query() else {
            return AttributedString(plainTitle)
        }

        return AttributedString(
            plainTitle.highlightedStringWithKeyword(
                query,
                primaryTextColor: UIColor(titleTextColor),
                highlightedTextColor: UIColor(colorAssets.textHighlightColor)
            )
        )
    }

    var note: AttributedString? {
        if let nodeDescription = result.note,
            let query = query(),
           nodeDescription.containsIgnoringCaseAndDiacritics(searchText: query) {
            AttributedString(
                nodeDescription.highlightedStringWithKeyword(
                    query,
                    primaryTextColor: UIColor(colorAssets.nodeDescriptionTextNormalColor),
                    highlightedTextColor: UIColor(colorAssets.textHighlightColor),
                    normalFont: .preferredFont(forTextStyle: .caption1),
                    highlightedFont: .preferredFont(style: .caption1, weight: .bold)
                )
            )
        } else {
            nil
        }
    }

    var tagListViewModel: HorizontalTagListViewModel? {
        let tags: [AttributedString] = result.tags.compactMap { inputTag in
            guard let query = query()?.removingFirstLeadingHash(),
                  case let tag = "#" + inputTag,
                  tag.containsIgnoringCaseAndDiacritics(searchText: query) else {
                return nil
            }

            var attributedString = AttributedString(
                tag
                    .forceLeftToRight()
                    .highlightedStringWithKeyword(
                        query,
                        primaryTextColor: UIColor(colorAssets.tagsTextColor),
                        highlightedTextColor: UIColor(colorAssets.textHighlightColor)
                    )
            )

            attributedString.font = .subheadline.weight(.medium)
            return attributedString
        }

        return tags.isNotEmpty ? HorizontalTagListViewModel(tags: tags) : nil
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
