import MessageKit

extension MessageSizeCalculator {
    func configureAccessoryView() {
        incomingAccessoryViewSize = CGSize(width: 30, height: 30)
        outgoingAccessoryViewSize = CGSize(width: 30, height: 30)
        
        incomingAccessoryViewPadding = HorizontalEdgeInsets(left: 10, right: 10)
        outgoingAccessoryViewPadding = HorizontalEdgeInsets(left: 10, right: 10)
    }
}
