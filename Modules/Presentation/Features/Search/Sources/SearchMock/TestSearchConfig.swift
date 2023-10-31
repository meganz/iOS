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
                itemUnselected: UIImage(systemName: "circle")!
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
