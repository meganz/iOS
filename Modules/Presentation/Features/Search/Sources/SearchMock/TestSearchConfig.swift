import MEGADesignToken
import Search
import SwiftUI
import UIKit

extension SearchConfig {
    @MainActor public static var testConfig: Self {
        .init(
            chipAssets: .init(
                selectionIndicatorImage: UIImage(systemName: "ellipsis")!,
                closeIcon: UIImage(systemName: "ellipsis")!,
                selectedForeground: .white,
                selectedBackground: .green,
                normalForeground: .black,
                normalBackground: .white
            ),
            emptyViewAssetFactory: { _, _ in .testAssets },
            rowAssets: .init(
                contextImage: UIImage(systemName: "ellipsis")!,
                itemSelected: UIImage(systemName: "checkmark.circle")!,
                itemUnselected: UIImage(systemName: "circle")!,
                playImage: UIImage(systemName: "ellipsis")!,
                downloadedImage: UIImage(systemName: "ellipsis")!,
                moreList: UIImage(systemName: "ellipsis")!,
                moreGrid: UIImage(systemName: "ellipsis")!
            ),
            colorAssets: .init(
                unselectedBorderColor: Color("F7F7F7"),
                selectedBorderColor: Color("00A886"),
                titleTextColor: Color.primary,
                subtitleTextColor: Color.secondary,
                nodeDescriptionTextNormalColor: Color.secondary,
                textHighlightColor: .gray,
                vibrantColor: Color.red,
                resultPropertyColor: Color.gray, 
                verticalThumbnailFooterText: .white,
                verticalThumbnailFooterBackground: .black,
                verticalThumbnailPreviewBackground: .gray,
                verticalThumbnailTopIconsBackground: .white.opacity(0.4),
                listRowSeparator: .gray,
                checkmarkBackgroundTintColor: Color("00A886")
            ),
            contextPreviewFactory: .test
        )
    }
}

extension SearchConfig.ContextPreviewFactory {
    @MainActor static var test: Self {
        SearchConfig.ContextPreviewFactory(
            previewContentForResult: { _ in
                    .init(
                        actions: [
                            .init(title: "Select", imageName: "checkmark.circle", handler: {})
                        ],
                        previewMode: .preview({
                            UIHostingController(rootView: Text("I'm preview"))
                        })
                    )
            }
        )
    }
}

extension SearchConfig.EmptyViewAssets {
    public static var testAssets: Self {
        .init(
            image: Image(systemName: "magnifyingglass"),
            title: "No results",
            titleTextColor: TokenColors.Icon.secondary.swiftUI,
            actions: []
        )
    }
}
