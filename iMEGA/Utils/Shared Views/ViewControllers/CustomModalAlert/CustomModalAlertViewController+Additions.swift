extension CustomModalAlertViewController {
    @objc func updateDetailAttributedTextWithLink(_ detail: NSAttributedString) {
        detailLabel?.isHidden = true
        detailTextView?.isHidden = false
        detailTextView?.attributedText = detail
    }
    
    @objc func mainViewShadowColor() -> UIColor {
        MEGAAppColor.Black._000000.uiColor
    }
}
