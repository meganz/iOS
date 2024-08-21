import Combine

final class AutoGrowingTextView: UITextView {
    private var subscriptions = Set<AnyCancellable>()
    private let numberOfLinesBeforeScroll: UInt
    private let updatedLayout: (() -> Void) -> Void

    private var lineHeight: CGFloat {
        let placeholderTextView = UITextView()
        placeholderTextView.textContainerInset = .zero
        placeholderTextView.text = ""
        placeholderTextView.font = font
        let size = CGSize(width: frame.size.width, height: .infinity)
        let estimatedSize = placeholderTextView.sizeThatFits(size)
        return estimatedSize.height
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize

        if size.height == UIView.noIntrinsicMetric {
            size.height = layoutManager.usedRect(for: textContainer).height
            let maxHeight = CGFloat(numberOfLinesBeforeScroll) * lineHeight
            if size.height > maxHeight {
                size.height = maxHeight
            }
        }

        return size
    }

    init(
        frame: CGRect,
        textContainer: NSTextContainer? = nil,
        numberOfLinesBeforeScroll: UInt = 5,
        updatedLayout: @escaping (() -> Void) -> Void
    ) {
        self.numberOfLinesBeforeScroll = numberOfLinesBeforeScroll
        self.updatedLayout = updatedLayout
        super.init(frame: frame, textContainer: textContainer)
        textContainerInset = .zero
        listenToTextChangeNotification()
        listenToOrientationDidChangeNotification()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func listenToTextChangeNotification() {
        NotificationCenter
            .default
            .publisher(for: UITextView.textDidChangeNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                updatedLayout {
                    self.invalidateIntrinsicContentSize()
                }
            }
            .store(in: &subscriptions)
    }

    private func listenToOrientationDidChangeNotification() {
        NotificationCenter
            .default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .debounce(for: .seconds(0.6), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                updatedLayout {
                    self.invalidateIntrinsicContentSize()
                }
            }
            .store(in: &subscriptions)
    }
}
