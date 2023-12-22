import SwiftUI
import UIKit

extension SearchConfig {
    static let example: SearchConfig = .init(
        chipAssets: .example,
        emptyViewAssetFactory: SearchConfig.EmptyViewAssets.exampleFactory,
        rowAssets: .example,
        colorAssets: .example,
        contextPreviewFactory: .example
    )
}

extension SearchConfig.ContextPreviewFactory {
    static let example: Self = .init(
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
    static let example: Self = .init(
        selectionIndicatorImage: UIImage(systemName: "ellipsis")!, 
        closeIcon: UIImage(systemName: "ellipsis")!,
        selectedForeground: .white,
        selectedBackground: .green,
        normalForeground: .black,
        normalBackground: .gray
    )
}

extension SearchConfig.EmptyViewAssets {
    
    static let exampleFactory: (SearchChipEntity?) -> Self = { _ in
            .init(
                image: Image(systemName: "magnifyingglass.circle.fill"),
                title: "No results",
                foregroundColor: Color(red: 209.0/255.0, green: 209.0/255.0, blue: 209.0/255.0)
            )
    }
}

extension SearchConfig.RowAssets {
    static let example: Self = .init(
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
    static let example: Self = .init(
        F7F7F7: Color("F7F7F7"),
        _161616: Color("161616"),
        _545458: Color("545458"),
        CE0A11: Color("CE0A11"),
        F30C14: Color("F30C14"),
        F95C61: Color("F95C61"),
        F7363D: Color("F7363D"),
        _1C1C1E: Color("1C1C1E"),
        _00A886: Color("00A886"),
        _3C3C43: Color("3C3C43")
    )
}
