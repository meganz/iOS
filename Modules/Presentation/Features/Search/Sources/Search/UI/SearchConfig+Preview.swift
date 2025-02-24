import MEGADesignToken
import SwiftUI
import UIKit

extension SearchConfig {
    @MainActor static let example: SearchConfig = .init(
        chipAssets: .example,
        emptyViewAssetFactory: SearchConfig.EmptyViewAssets.exampleFactory,
        rowAssets: .example,
        colorAssets: .example,
        contextPreviewFactory: .example
    )
}

extension SearchConfig.ContextPreviewFactory {
    @MainActor static let example: Self = .init(
        previewContentForResult: { result in
            return .init(
                actions: [],
                previewMode: .preview({
                    UIHostingController(rootView: Text(result.title))
                })
            )
        }
    )
}

extension SearchConfig.ChipAssets {
    @MainActor static let example: Self = .init(
        selectionIndicatorImage: UIImage(systemName: "ellipsis")!,
        closeIcon: UIImage(systemName: "ellipsis")!,
        selectedForeground: .white,
        selectedBackground: .green,
        normalForeground: .black,
        normalBackground: .gray
    )
}

extension SearchConfig.EmptyViewAssets {
    
    @MainActor static let exampleFactory: (SearchChipEntity?, SearchQuery) -> Self = { _, _ in
            .init(
                image: Image(systemName: "magnifyingglass.circle.fill"),
                title: "No results",
                titleTextColor: TokenColors.Icon.secondary.swiftUI,
                actions: []
            )
    }
}

extension SearchConfig.RowAssets {
    @MainActor static let example: Self = .init(
        contextImage: UIImage(systemName: "ellipsis")!,
        itemSelected: UIImage(systemName: "checkmark.circle")!,
        itemUnselected: UIImage(systemName: "circle")!,
        playImage: .init(systemName: "ellipsis")!,
        downloadedImage: .init(systemName: "ellipsis")!,
        moreList: UIImage(systemName: "ellipsis")!,
        moreGrid: UIImage(systemName: "ellipsis")!
    )
}

extension SearchConfig.ColorAssets {
    @MainActor static let example: Self = .init(
        unselectedBorderColor: Color("F7F7F7"),
        selectedBorderColor: Color("00A886"),
        titleTextColor: Color.primary,
        subtitleTextColor: Color.secondary,
        nodeDescriptionTextNormalColor: Color.secondary,
        textHighlightColor: .gray,
        vibrantColor: Color.red,
        resultPropertyColor: .gray, 
        verticalThumbnailFooterText: .white,
        verticalThumbnailFooterBackground: .black,
        verticalThumbnailPreviewBackground: .gray,
        verticalThumbnailTopIconsBackground: .white.opacity(0.4),
        listRowSeparator: .gray,
        checkmarkBackgroundTintColor: Color("00A886"),
        listHeaderTextColor: .black,
        listHeaderBackgroundColor: .white
    )
}
