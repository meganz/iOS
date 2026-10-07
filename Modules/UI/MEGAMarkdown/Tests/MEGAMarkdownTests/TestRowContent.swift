import UIKit

/// Counts how often row cells measure their content.
@MainActor
final class SizingCounter {
    private(set) var total = 0
    private(set) var byItem: [Int: Int] = [:]

    func add(item: Int) {
        total += 1
        byItem[item, default: 0] += 1
    }

    func reset() {
        total = 0
        byItem = [:]
    }
}

/// Row content with a fixed height and a text field, for container tests without SwiftUI.
struct TestRowContent: UIContentConfiguration {
    var item: Int
    var height: CGFloat
    var text = ""
    let counter: SizingCounter

    func makeContentView() -> any UIView & UIContentView {
        TestRowContentView(configuration: self)
    }

    func updated(for state: any UIConfigurationState) -> TestRowContent {
        self
    }
}

/// The view of `TestRowContent`. Its size is the configured height at any width.
final class TestRowContentView: UIView, UIContentView {
    let textField = UITextField()
    /// How often a configuration was applied to this view, so a test can tell a reconfigure from a new cell.
    private(set) var applyCount = 0

    var configuration: any UIContentConfiguration {
        didSet { apply() }
    }

    var rowContent: TestRowContent? {
        configuration as? TestRowContent
    }

    init(configuration: TestRowContent) {
        self.configuration = configuration
        super.init(frame: .zero)
        textField.frame = CGRect(x: 0, y: 0, width: 200, height: 20)
        addSubview(textField)
        apply()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        guard let rowContent else { return .zero }
        rowContent.counter.add(item: rowContent.item)
        return CGSize(width: targetSize.width, height: rowContent.height)
    }

    private func apply() {
        applyCount += 1
        // Setting the same text again is cheap and keeps the caret.
        if let rowContent, textField.text != rowContent.text { textField.text = rowContent.text }
    }
}
