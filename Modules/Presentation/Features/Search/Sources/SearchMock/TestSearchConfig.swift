import MEGADesignToken
import Search
import SwiftUI
import UIKit

extension SearchConfig {
    public static var testConfig: Self {
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
                vibrantColor: Color.red, 
                resultPropertyColor: Color.gray, 
                verticalThumbnailFooterText: .white,
                verticalThumbnailFooterBackground: .black,
                verticalThumbnailPreviewBackground: .gray,
                verticalThumbnailTopIconsBackground: .white.opacity(0.4),
                verticalThumbnailTopPropertyColor: .gray,
                listRowSeparator: .gray,
                F7F7F7: Color("F7F7F7"),
                _161616: Color("161616"),
                _545458: Color("545458"),
                CE0A11: Color("CE0A11"),
                F30C14: Color("F30C14"),
                F95C61: Color("F95C61"),
                F7363D: Color("F7363D"),
                _1C1C1E: Color("1C1C1E"),
                _00A886: Color("00A886"),
                _3C3C43: Color("3C3C43"), 
                checkmarkBackgroundTintColor: Color("00A886")
            ),
            contextPreviewFactory: .test
        )
    }
}

extension SearchConfig.ContextPreviewFactory {
    static var test: Self {
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
