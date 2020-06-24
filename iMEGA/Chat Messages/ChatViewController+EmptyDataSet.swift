import UIKit

extension ChatViewController: DZNEmptyDataSetSource {

    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {

        if chatRoomDelegate.loadingState {
            return UIImageView(image: #imageLiteral(resourceName: "chatroomLoading"))
        }
        
        return wrappedIntroductionView()
    }
    
    private func wrappedIntroductionView() -> UIView {
        // DZNEmptyDataSet fills the whole view but we need the introduction view to aligned to the top without filling the whole screen.
        let placeholderView = UIView()
        placeholderView.backgroundColor = .clear
        
        let chatMessageHeaderView =  ChatViewIntroductionHeaderView.instanceFromNib
        chatMessageHeaderView.chatRoom = chatRoom
        
        let estimatedSize = chatMessageHeaderView.sizeThatFits(
            CGSize(width: messagesCollectionView.bounds.width,
                   height: .greatestFiniteMagnitude)
        )
        
        chatMessageHeaderView.bounds = CGRect(origin: .zero, size: estimatedSize)
        chatMessageHeaderView.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.addSubview(chatMessageHeaderView)
        
        NSLayoutConstraint.activate([
            chatMessageHeaderView.topAnchor.constraint(equalTo: placeholderView.topAnchor),
            chatMessageHeaderView.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor),
            chatMessageHeaderView.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor),
            chatMessageHeaderView.heightAnchor.constraint(equalToConstant: chatMessageHeaderView.bounds.height)
        ])
        
        return placeholderView
    }
}

extension ChatViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
}
