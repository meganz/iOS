import Combine

final class AutoGrowingTextView: UITextView {
    private var subscriptions = Set<AnyCancellable>()
    private let numberOfLinesBeforeScroll: UInt

    init(
        frame: CGRect,
        textContainer: NSTextContainer? = nil,
        numberOfLinesBeforeScroll: UInt = 5
    ) {
        self.numberOfLinesBeforeScroll = numberOfLinesBeforeScroll
        super.init(frame: frame, textContainer: textContainer)
        textContainerInset = .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        size.height = lineHeight(for: text ?? "", width: size.width)
        let maxHeight = CGFloat(numberOfLinesBeforeScroll) * lineHeight(for: "", width: size.width)
        if size.height > maxHeight {
            size.height = maxHeight
        }

        return size
    }

    private func lineHeight(for text: String, width: CGFloat) -> CGFloat {
        let placeholderTextView = UITextView()
        placeholderTextView.textContainerInset = .zero
        placeholderTextView.text = text
        placeholderTextView.font = font
        let size = CGSize(width: width, height: .infinity)
        let estimatedSize = placeholderTextView.sizeThatFits(size)
        return estimatedSize.height
    }
}
