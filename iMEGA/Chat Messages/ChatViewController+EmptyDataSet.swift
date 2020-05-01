import UIKit

extension ChatViewController: DZNEmptyDataSetSource {

    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        return UIImageView(image: #imageLiteral(resourceName: "chatroomLoading"))
    }
}

extension ChatViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return chatRoomDelegate.loadingState
    }
}
