extension CustomModalAlertViewController {
    @objc func updateDetailAttributedTextWithLink(_ detail: NSAttributedString) {
        detailLabel.isHidden = true
        detailTextView.isHidden = false
        detailTextView.attributedText = detail
    }
}
