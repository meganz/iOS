
final class MessageInputBarComponentsSizeCalculator {
    func calculateTypingLabelSize(fitSize: CGSize) -> CGSize {
        let auxLabel = UILabel()
        auxLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        auxLabel.adjustsFontForContentSizeCategory = true
        auxLabel.text = "is typing..."
        
        return auxLabel.sizeThatFits(fitSize)
    }
    
    func calculateTextViewSize(fitSize: CGSize) -> CGSize {
        let auxTextView = UITextView()
        auxTextView.font = UIFont.preferredFont(forTextStyle: .body)
        auxTextView.adjustsFontForContentSizeCategory = true
        auxTextView.text = "Message..."
        return auxTextView.sizeThatFits(fitSize)
    }
}
