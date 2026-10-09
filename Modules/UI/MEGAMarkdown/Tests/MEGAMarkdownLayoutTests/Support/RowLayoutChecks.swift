import MEGAMarkdown
@testable import MEGAMarkdownEditor
import UIKit

extension RichLayoutHarness {
    /// Checks every cell on screen and returns one line per broken rule. Empty means the layout is right.
    /// Rules: the stored height is measured, the cell has the stored height, the cell is as tall as its content,
    /// the text view shows the text of its own row, and no cell overlaps the next one.
    func rowProblems() -> [String] {
        let view = list.view
        guard let layout = view.collectionViewLayout as? MarkdownRowLayout else { return ["the list has no MarkdownRowLayout"] }
        var problems: [String] = []
        var frames: [(item: Int, frame: CGRect)] = []
        for item in view.indexPathsForVisibleItems.map(\.item).sorted() {
            guard let cell = list.cell(forItem: item) else { continue }
            let stored = list.itemFrame(at: item).height
            let content = ceil(cell.contentView.systemLayoutSizeFitting(
                CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height)
            if !layout.heights.isMeasured(item) {
                problems.append("item \(item): the height \(stored) is an estimate")
            }
            if abs(cell.frame.height - stored) > 0.5 {
                problems.append("item \(item): stored height \(stored), cell height \(cell.frame.height)")
            }
            if abs(content - stored) > 0.5 {
                problems.append("item \(item): stored height \(stored), content height \(content)")
            }
            let row = adapter.row(forItem: item).row
            if let expected = model.row(at: row).block.richText?.text,
               let shown = adapter.textView(forItem: item)?.text,
               shown != expected {
                problems.append("item \(item): shows '\(shown)', row \(row) has '\(expected)'")
            }
            frames.append((item, cell.frame))
        }
        for (upper, lower) in zip(frames, frames.dropFirst()) where upper.frame.maxY > lower.frame.minY + 0.5 {
            problems.append("item \(upper.item) ends at \(upper.frame.maxY), below the start of item \(lower.item) at \(lower.frame.minY)")
        }
        return problems
    }
}
