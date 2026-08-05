import MEGADesignToken

extension CustomModalAlertViewController {
    @objc func updateDetailAttributedTextWithLink(_ detail: NSAttributedString) {
        detailLabel?.isHidden = true
        detailTextView?.isHidden = false
        detailTextView?.attributedText = detail
        detailTextView?.delegate = self
    }
    
    @objc func mainViewShadowColor() -> UIColor {
        TokenColors.Text.primary
    }
}

// MARK: - UITextViewDelegate
extension CustomModalAlertViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        guard case .link(let url) = textItem.content,
              let invalidURL = URL(string: "invalid://urlLink"),
              url == invalidURL else {
            return defaultAction
        }

        viewModel.invalidLinkTapped()
        return nil
    }
}
