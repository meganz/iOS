import Search
import SwiftUI
import UIKit

extension SearchConfig {
    public static var testConfig: Self {
        .init(
            chipAssets: .init(
                selectedForeground: .white,
                selectedBackground: .green,
                normalForeground: .black,
                normalBackground: .gray
            ),
            emptyViewAssetFactory: { _ in .testAssets },
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
                F7F7F7: Color("F7F7F7"),
                _161616: Color("161616"),
                _545458: Color("545458"),
                CE0A11: Color("CE0A11"),
                F30C14: Color("F30C14"),
                F95C61: Color("F95C61"),
                F7363D: Color("F7363D"),
                _1C1C1E: Color("1C1C1E")
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
            foregroundColor: Color(red: 209.0/255.0, green: 209.0/255.0, blue: 209.0/255.0)
        )
    }
}
