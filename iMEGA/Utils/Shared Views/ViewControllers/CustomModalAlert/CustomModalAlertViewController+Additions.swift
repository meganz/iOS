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
    public func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if let invalidURL = URL(string: "invalid://urlLink"), url == invalidURL {
            viewModel.invalidLinkTapped()
            return false
        }
        
        return true
    }
}
