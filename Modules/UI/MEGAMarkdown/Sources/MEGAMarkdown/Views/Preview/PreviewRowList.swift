import MEGADesignToken
import SwiftUI
import UIKit

/// The scrolling rows of `MarkdownPreview`: a `MarkdownRowList` with one hosted `PreviewRowView` per row.
/// Only the cells on screen exist, so memory stays flat however far the user scrolls.
struct PreviewRowList: UIViewRepresentable {
    let store: PreviewRowStore
    /// Grows for a new text. The list then reads every row again and goes to the top.
    let generation: Int
    /// Rows in `store` when SwiftUI made this value. More rows than the list has are appended.
    let rowCount: Int
    let isComplete: Bool
    /// Lines in the whole text. The read progress is a source line divided by it.
    var lineCount = 0
    /// False while the rows on screen belong to an older text. A restore line then waits for the new rows.
    var showsCurrentText = true
    let baseURL: URL?
    let restoreLine: Int?
    let onReadingPositionChange: ((MarkdownReadingPosition) -> Void)?
    /// The SwiftUI safe area of the preview, host bars included. The list fills it and keeps its rows clear of it.
    var safeArea = EdgeInsets()

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MarkdownRowListView {
        let view = context.coordinator.list.view
        view.alwaysBounceVertical = true
        view.accessibilityIdentifier = "markdown.preview.list"
        view.delegate = context.coordinator
        context.coordinator.selection.attach()
        return view
    }

    func updateUIView(_ view: MarkdownRowListView, context: Context) {
        // Hosts and snapshot tests set the text size, direction and color scheme only through SwiftUI.
        // The hosted rows read them from the cell traits, so they go on the list view as trait overrides.
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
        context.coordinator.update(self, environment: environment)
    }

    static func dismantleUIView(_ view: MarkdownRowListView, coordinator: Coordinator) {
        // A late report would overwrite the host's saved place with a row of a view that is gone.
        coordinator.stop()
    }
}
