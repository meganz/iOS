import MEGADesignToken
import MEGAMarkdown
import SwiftUI
import UIKit

/// The scrolling rows of rich mode: the adapter's `MarkdownRowList` in SwiftUI.
struct RichEditorRowList: UIViewRepresentable {
    let adapter: RichRowAdapter
    let baseURL: URL?

    /// Lives as long as the list view, so the selection over rows has an owner.
    func makeCoordinator() -> CrossBlockSelectionController {
        CrossBlockSelectionController(adapter: adapter)
    }

    func makeUIView(context: Context) -> MarkdownRowListView {
        let view = adapter.list.view
        // Space above the first row and below the last.
        view.contentInset = UIEdgeInsets(top: TokenSpacing._5, left: 0, bottom: TokenSpacing._5, right: 0)
        view.alwaysBounceVertical = true
        view.accessibilityIdentifier = "editor.rich.list"
        adapter.list.reloadAll()
        context.coordinator.attach()
        return view
    }

    static func dismantleUIView(_ view: MarkdownRowListView, coordinator: CrossBlockSelectionController) {
        coordinator.detach()
        // The editor is leaving. SwiftUI may remove the rows in any order, so drop the keyboard here.
        view.endEditing(true)
    }

    func updateUIView(_ view: MarkdownRowListView, context: Context) {
        // Hosted rows read the text size, direction and color scheme from the cell traits,
        // so the SwiftUI values go on the list view as trait overrides.
        let environment = context.environment
        let overrides = view.traitOverrides
        // Reading a trait that has no override throws, so check `contains` first.
        let category = UIContentSizeCategory(environment.dynamicTypeSize)
        if !overrides.contains(UITraitPreferredContentSizeCategory.self) || overrides.preferredContentSizeCategory != category {
            view.traitOverrides.preferredContentSizeCategory = category
        }
        let direction: UITraitEnvironmentLayoutDirection = environment.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        if !overrides.contains(UITraitLayoutDirection.self) || overrides.layoutDirection != direction {
            view.traitOverrides.layoutDirection = direction
        }
        let style: UIUserInterfaceStyle = environment.colorScheme == .dark ? .dark : .light
        if !overrides.contains(UITraitUserInterfaceStyle.self) || overrides.userInterfaceStyle != style {
            view.traitOverrides.userInterfaceStyle = style
        }
        adapter.baseURL = baseURL
        adapter.imageLoading = environment.markdownImageLoading
        adapter.theme = environment.markdownTheme
        adapter.strings = environment.markdownEditorStrings
    }
}
