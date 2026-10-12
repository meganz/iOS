import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import MEGATextEditor
import UIKit

/// The selectors the bottom bar items call. Each text editor screen implements them.
@MainActor
@objc protocol TextEditorBarItemTarget: AnyObject {
    func downloadTapped()
    func editTapped()
    func exportFileTapped(button: UIBarButtonItem)
    func importTapped()
}

/// Bar items that the text editor and the Markdown screen share.
@MainActor
enum TextEditorBarItems {
    /// Shows the file name. On iOS 26 it is a title view, and before that a plain title.
    static func applyTitle(_ title: String, to navigationItem: UINavigationItem, shouldEnableGlassEffect: Bool) {
        if #available(iOS 26.0, *) {
            navigationItem.titleView = NavigationTitleView(title: title)
                .toWrappedUIView(
                    shouldEnableGlassEffect: shouldEnableGlassEffect,
                    padding: .init(top: TokenSpacing._3, leading: TokenSpacing._3, bottom: TokenSpacing._3, trailing: TokenSpacing._3)
                )
        } else {
            navigationItem.title = title
        }
    }

    /// Download, then Edit unless the access is read only, then Export for the owner or else Import.
    /// A flexible space sits between the items.
    static func bottomBarItems(accessLevel: NodeAccessTypeEntity, target: some TextEditorBarItemTarget) -> [UIBarButtonItem] {
        let items = MarkdownTextEditorBottomBarItem.items(for: accessLevel).map { makeItem($0, target: target) }
        return items.enumerated().flatMap { index, item in
            index == 0 ? [item] : [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), item]
        }
    }

    private static func makeItem(_ item: MarkdownTextEditorBottomBarItem, target: some TextEditorBarItemTarget) -> UIBarButtonItem {
        switch item {
        case .download:
            UIBarButtonItem(image: MEGAAssets.UIImage.offline, style: .plain, target: target, action: #selector((any TextEditorBarItemTarget).downloadTapped))
        case .edit:
            UIBarButtonItem(image: MEGAAssets.UIImage.edittext, style: .plain, target: target, action: #selector((any TextEditorBarItemTarget).editTapped))
        case .export:
            UIBarButtonItem(
                image: MEGAAssets.UIImage.downloadToDisk,
                style: .plain,
                target: target,
                action: #selector((any TextEditorBarItemTarget).exportFileTapped(button:))
            )
        case .import:
            UIBarButtonItem(image: MEGAAssets.UIImage.import, style: .plain, target: target, action: #selector((any TextEditorBarItemTarget).importTapped))
        }
    }
}
