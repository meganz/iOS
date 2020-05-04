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
}

extension ChatViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
//    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
//        return chatRoomDelegate.messages.count == 0
//    }
}
