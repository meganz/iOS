
import PanModal

class ReactedEmojisUsersListViewController: UIViewController  {

    var isShortFormEnabled = true
    let headerView = EmojiCarousalView.instanceFromNib

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

// MARK: - Pan Modal Presentable

extension ReactedEmojisUsersListViewController: PanModalPresentable {

    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }

    var shortFormHeight: PanModalHeight {
        return isShortFormEnabled ? .contentHeight(300.0) : longFormHeight
    }

    var scrollIndicatorInsets: UIEdgeInsets {
        let bottomOffset = presentingViewController?.bottomLayoutGuide.length ?? 0
        return UIEdgeInsets(top: headerView.frame.size.height, left: 0, bottom: bottomOffset, right: 0)
    }

    var anchorModalToLongForm: Bool {
        return false
    }

    func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let location = panModalGestureRecognizer.location(in: view)
        return headerView.frame.contains(location)
    }

    func willTransition(to state: PanModalPresentationController.PresentationState) {
        guard isShortFormEnabled, case .longForm = state
            else { return }

        isShortFormEnabled = false
        panModalSetNeedsLayoutUpdate()
    }
}
