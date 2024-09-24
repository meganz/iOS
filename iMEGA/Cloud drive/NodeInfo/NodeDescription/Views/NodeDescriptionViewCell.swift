import MEGADesignToken
import MEGAUI
import UIKit

final class NodeDescriptionViewCell: UITableViewCell {
    private let textView: AutoGrowingTextView
    
    /// Biz logic requires us tracking user's tap on the `textView`.
    /// Usually we can use `textViewDidBeginEditing` to check when the textView become active, but that doesn't satistfy the biz requirement
    /// because `textViewDidBeginEditing` can be invoked by system events (e.g: It can be unfocused by an alert view and then get automatically re-focused when the alert dismisses).
    /// For that reason we need to use a tap guesture to really detect user's tap and  activate the textView.
    private lazy var textViewTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapped(_:)))
        gesture.delegate = privateGestureDelegate
        return gesture
    }()
    
    private lazy var privateGestureDelegate = GestureRecognizerDelegate()

    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    // Due to the limitation of UITableView's deque reuse API, we can't inject viewModel at init time so
    // viewModel has to be optional
    var viewModel: NodeDescriptionCellViewModel? {
        didSet {
            viewModel?.onUpdate = { [weak self] in
                self?.updateUI()
            }
            self.updateUI()
            viewModel?.dismissKeyboard = { [weak textView] in
                textView?.resignFirstResponder()
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textView = AutoGrowingTextView(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        guard let viewModel else { return .zero }

        // Actual width available for the text view is cell width - textview insets
        var targetSize = targetSize
        targetSize.width -= viewModel.textViewEdgeInsets.left + viewModel.textViewEdgeInsets.right

        // Height required is height it takes for the width + textview insets
        var size = textView.sizeThatFits(targetSize)
        size.height += viewModel.textViewEdgeInsets.top + viewModel.textViewEdgeInsets.bottom
        
        return size
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateUI() {
        guard let viewModel else { return }
        textView.isEditable = !viewModel.editingDisabled()
        textView.text = viewModel.displayText(isEditing: textView.isFirstResponder)
        textView.textColor = textColor(isPlaceholderText: viewModel.isPlaceholder)
        updateInsets(viewModel.textViewEdgeInsets)
    }

    private func configureUI() {
        selectionStyle = .none
        backgroundColor = TokenColors.Background.page
        wrap(textView, inside: contentView)
        configure(textView: textView)
        contentView.addGestureRecognizer(textViewTapGesture)
    }

    private func configure(textView: UITextView) {
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.returnKeyType = .done
        textView.delegate = self
        if #available(iOS 17.0, *) {
            textView.inlinePredictionType = .no
        }
    }
    
    private func textColor(isPlaceholderText: Bool) -> UIColor {
        isPlaceholderText ? TokenColors.Text.secondary : TokenColors.Text.primary
    }
    
    private func wrap(_ textView: UITextView, inside content: UIView) {
        textView.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(textView)

        topConstraint = contentView.topAnchor.constraint(equalTo: textView.topAnchor)
        bottomConstraint = contentView.bottomAnchor.constraint(equalTo: textView.bottomAnchor)
        leadingConstraint = contentView.leadingAnchor.constraint(equalTo: textView.leadingAnchor)
        trailingConstraint = contentView.trailingAnchor.constraint(equalTo: textView.trailingAnchor)

        topConstraint?.isActive = true
        bottomConstraint?.isActive = true
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
    }

    private func updateInsets(_ insets: UIEdgeInsets) {
        topConstraint?.constant = -insets.top
        bottomConstraint?.constant = insets.bottom
        leadingConstraint?.constant = -insets.left
        trailingConstraint?.constant = insets.right
        layoutIfNeeded()
    }
    
    @objc private func textViewTapped(_ sender: UITapGestureRecognizer) {
        guard !textView.isFirstResponder else { return }
        viewModel?.trackNodeInfoDescriptionEntered()
    }
}

extension NodeDescriptionViewCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        viewModel?.isTextViewFocused(true)
        textView.textColor = textColor(isPlaceholderText: false)

        // Note: There are 2 cases where textViewDidBeginEditing is invoked: (1) when user proactive click on the textField
        // and (2) when the textView is already active and then get interupted by a alertView (in our case the "Confirm close?" alert
        // For (1), we need to clear the textView content, but for 2 wee need to maintain that content, thus we need to check for both
        // `viewModel?.isPlaceholder == true && textView.text == viewModel?.placeholderText`
        if viewModel?.isPlaceholder == true && textView.text == viewModel?.placeholderText {
            textView.text = nil
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        viewModel?.isTextViewFocused(false)
        if textView.text?.isEmpty == true, viewModel?.isPlaceholder == true {
            textView.text = viewModel?.placeholderText
            textView.textColor = textColor(isPlaceholderText: true)
        }
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let textViewText = textView.text ?? ""
        guard viewModel?.shouldEndEditing(for: text) == false else {
            textView.endEditing(true)
            viewModel?.trackNodeInfoDescriptionConfirmed()
            viewModel?.saveDescription(textViewText)
            return false
        }

        guard viewModel?.shouldChangeTextIn(in: range, currentText: textViewText, replacementText: text) == true else {
            let replacementText = viewModel?.truncateAndReplaceText(in: range, of: textViewText, with: text)
            textView.text = replacementText ?? textViewText
            viewModel?.descriptionUpdated(textView.text)
            return false
        }

        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        viewModel?.descriptionUpdated(textView.text)
    }
}

private final class GestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    true
  }
}
