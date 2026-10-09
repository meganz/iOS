import MEGADesignToken
import MEGAFoundation
import SwiftUI
import UIKit

extension PreviewRowList {
    /// Data source and delegate of the preview list. It also keeps the restore line and the top-line report
    /// (see `PreviewRowList+Restore.swift`).
    @MainActor
    final class Coordinator: NSObject {
        private(set) lazy var list = makeList()
        /// Block selection with the edit menu.
        private(set) lazy var selection = makeSelection()
        private(set) var store = PreviewRowStore()
        private var generation: Int?
        private(set) var isComplete = false
    private(set) var showsCurrentText = true
        private(set) var isStopped = false
        private var baseURL: URL?
        var onTopLineChange: ((Int) -> Void)?

        // MARK: Values the hosted rows read

        private var theme = MarkdownTheme.default
        private var strings = MarkdownPreviewStrings.english
        private var imageLoading = MarkdownImageLoading.altTextOnly
        /// The host's handler. Rows get `forwardingOpenURL`, so a new handler needs no new cells.
        private var openURL = OpenURLAction { _ in .systemAction }
        private var hasCheckedTheme = false
        private var hasLoggedFontFallback = false

        // MARK: Restore and report state

        var hasStarted = false
        var lastRestoreLine: Int?
        /// A restore line whose row is not parsed yet.
        var pendingRestoreLine: Int?
        /// A row to show at the top once the list has a size.
        var pendingJump: Int?
        /// After a jump, rows near the target size themselves over a few layout passes. The target stays at the top until `until`.
        var pin: (row: Int, until: CFTimeInterval)?
        var reportedLine: Int?
        var needsReport = false
        /// The SwiftUI safe area of the preview, host bars included.
        private var safeArea = EdgeInsets()

        /// Calls the host's current `openURL`. Hosted rows get this action.
        private(set) lazy var forwardingOpenURL = OpenURLAction { [weak self] url in
            MainActor.assumeIsolated { self?.openURL(url) }
            return .handled
        }

        private func makeList() -> MarkdownRowList {
            let list = MarkdownRowList(dataSource: self)
            // The list keeps its anchor in this callback. The restore runs after it in the same layout pass.
            let anchorLayout = list.view.onLayout
            list.view.onLayout = { [weak self] in
                anchorLayout?()
                self?.didLayout()
                self?.selection.refreshDisplay()
            }
            return list
        }

        private func makeSelection() -> PreviewSelectionController {
            let selection = PreviewSelectionController(list: list) { [weak self] in self?.store ?? PreviewRowStore() }
            // A restore must not move the list under a selection the user is making.
            selection.onBegin = { [weak self] in self?.endRestore() }
            return selection
        }

        // MARK: - Update

        /// Takes the new values. Reports and jumps wait for the next layout pass, because SwiftUI drops a state
        /// change made while it updates its views.
        func update(_ parent: PreviewRowList, environment: EnvironmentValues) {
            guard !isStopped else { return }
            safeArea = parent.safeArea
            updateInsets()
            baseURL = parent.baseURL
            onTopLineChange = parent.onTopLineChange
            openURL = environment.openURL
            updateTheme(environment.markdownTheme)
            let stringsChanged = strings != environment.markdownPreviewStrings
            strings = environment.markdownPreviewStrings
            let imageLoadingChanged = !imageLoading.isSameKind(as: environment.markdownImageLoading)
            imageLoading = environment.markdownImageLoading

            if !hasStarted || parent.restoreLine != lastRestoreLine {
                hasStarted = true
                lastRestoreLine = parent.restoreLine
                pendingRestoreLine = parent.restoreLine
            }
            isComplete = parent.isComplete
            showsCurrentText = parent.showsCurrentText
            if generation != parent.generation {
                let isNewText = generation != nil
                generation = parent.generation
                store = parent.store
                selection.clear()
                pin = nil
                pendingJump = nil
                reportedLine = nil
                list.reloadAll()
                // A new text starts at the top.
                if isNewText { list.view.contentOffset.y = -list.view.adjustedContentInset.top }
            } else {
                // SwiftUI can send a batch and an environment change in one update, so both run.
                if parent.rowCount > list.itemCount {
                    list.appendItems(count: parent.rowCount - list.itemCount)
                }
                var changed: [Int] = []
                if stringsChanged || imageLoadingChanged { changed = list.view.indexPathsForVisibleItems.map(list.item(for:)) }
                // A notice off screen may keep a height measured with the old text.
                if stringsChanged { changed += store.noticeRows }
                list.reconfigureItems(changed)
            }
            resolveRestore()
            needsReport = true
            list.view.setNeedsLayout()
        }

        func stop() {
            isStopped = true
            selection.detach()
            pin = nil
            pendingJump = nil
            pendingRestoreLine = nil
        }

        /// UIKit adds the window safe area by itself, and then cells never get it. Host bars added with
        /// `safeAreaInset` exist only in SwiftUI, so the rest of the SwiftUI safe area goes into `contentInset`.
        func updateInsets() {
            let view = list.view
            let top = max(0, safeArea.top - view.safeAreaInsets.top)
            let bottom = max(0, safeArea.bottom - view.safeAreaInsets.bottom)
            // Space above the first row and below the last.
            let inset = UIEdgeInsets(top: top + TokenSpacing._5, left: 0, bottom: bottom + TokenSpacing._5, right: 0)
            guard view.contentInset != inset else { return }
            // A list at the top stays at the top, so a taller top bar does not cover the first row.
            let isAtTop = view.contentOffset.y <= -view.adjustedContentInset.top + 0.5
            view.contentInset = inset
            view.verticalScrollIndicatorInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
            if isAtTop { view.contentOffset.y = -view.adjustedContentInset.top }
        }

        private func updateTheme(_ newTheme: MarkdownTheme) {
            guard newTheme != theme || !hasCheckedTheme else { return }
            hasCheckedTheme = true
            theme = newTheme
            list.theme = newTheme
            if !hasLoggedFontFallback, !newTheme.resolved(for: list.view.traitCollection).usesThemeFonts {
                hasLoggedFontFallback = true
                MEGALog.log(level: .info, message: "[MarkdownPreview] The theme has custom fonts. Row height guesses use the default fonts.")
            }
        }

        // MARK: - Hosted rows

        /// The SwiftUI environment does not reach hosted cells, so the values the rows read are passed on here.
        private func content(for row: PreviewRow, item: Int) -> some View {
            PreviewRowView(row: row, baseURL: baseURL)
                // Side padding sits in each row, so every cell spans the full width.
                .padding(.horizontal, TokenSpacing._5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.markdownTheme, theme)
                .environment(\.markdownPreviewStrings, strings)
                .environment(\.markdownImageLoading, imageLoading)
                .environment(\.openURL, forwardingOpenURL)
                // A reused cell would keep the sideways scroll of the old row. Other rows keep one identity, which is cheaper.
                .id(row.scrollsSideways ? item : -1)
        }
    }
}

// MARK: - MarkdownRowListDataSource

extension PreviewRowList.Coordinator: MarkdownRowListDataSource {
    var itemCount: Int { store.count }

    func configure(_ cell: MarkdownRowCell, forItem item: Int) {
        guard item < store.count else { return }
        let content = content(for: store[item], item: item)
        cell.contentConfiguration = UIHostingConfiguration { content }
            .margins(.all, 0)
            .minSize(height: 0)
    }

    func estimatedHeight(ofItem item: Int, using estimator: MarkdownRowEstimator) -> CGFloat {
        estimator.height(of: store[item])
    }

    /// An image row changes its height when the image loads.
    func alwaysSizes(item: Int) -> Bool {
        if case .block(let block) = store[item].content, case .image = block.kind { return true }
        return false
    }
}

// MARK: - UICollectionViewDelegate

extension PreviewRowList.Coordinator: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let item = list.item(for: indexPath)
        guard item < store.count, store[item].scrollsSideways else { return }
        // SwiftUI makes its scroll view in the content's layout pass, so run that pass first.
        cell.contentView.layoutIfNeeded()
        // Only the list may scroll to the top on a status bar tap.
        var pending: [UIView] = [cell.contentView]
        while let view = pending.popLast() {
            if let scrollView = view as? UIScrollView, scrollView.scrollsToTop { scrollView.scrollsToTop = false }
            pending.append(contentsOf: view.subviews)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        endRestore()
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        endRestore()
        return true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // The report runs in the layout pass that follows every scroll.
        needsReport = true
    }
}

// MARK: - Row helpers

extension PreviewRow {
    /// True for a row with its own sideways scroll view: code and tables.
    var scrollsSideways: Bool {
        switch content {
        case .codePiece, .plainText, .tablePage:
            true
        case .block(let block):
            switch block.kind {
            case .codeBlock, .table, .blockQuote, .list: true
            case .heading, .paragraph, .thematicBreak, .image: false
            }
        case .textPiece, .notice:
            false
        }
    }
}

extension MarkdownImageLoading {
    /// Compares the case only. A host may pass a new provider closure on every update.
    func isSameKind(as other: MarkdownImageLoading) -> Bool {
        switch (self, other) {
        case (.altTextOnly, .altTextOnly), (.remote, .remote), (.provided, .provided): true
        default: false
        }
    }
}
