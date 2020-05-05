import UIKit

extension ChatViewController: DZNEmptyDataSetSource {

    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {

        if chatRoomDelegate.loadingState {
            return UIImageView(image: #imageLiteral(resourceName: "chatroomLoading"))
        }
        let chatMessageHeaderView =  ChatViewIntroductionHeaderView.instanceFromNib
        chatMessageHeaderView.chatRoom = chatRoom
        return chatMessageHeaderView
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        let chatMessageHeaderView =  ChatViewIntroductionHeaderView.instanceFromNib
        chatMessageHeaderView.chatRoom = chatRoom
        let emptyDataSetView = scrollView.subviews.filter { NSStringFromClass(type(of: $0)) == "DZNEmptyDataSetView" }.first
        let size = chatMessageHeaderView.sizeThatFits(emptyDataSetView!.bounds.size)
        return -(emptyDataSetView!.center.y - size.height / 2)
    }
}

extension ChatViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
}
