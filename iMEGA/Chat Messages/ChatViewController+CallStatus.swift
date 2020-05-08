import UIKit

extension ChatViewController {
    
    func setTopBannerButton(title: String, color: UIColor) {
        topBannerButton.backgroundColor = color
        topBannerButton.setTitle(title, for: .normal)
    }
    
    func showTopBannerButton() {
        if topBannerButton.isHidden {
            topBannerButton.isHidden = false
            topBannerButtonTopConstraint?.constant = 0
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func hideTopBannerButton() {
        if !topBannerButton.isHidden {
            topBannerButtonTopConstraint?.constant = -44
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            }) { finished in
                if finished {
                    self.topBannerButton.isHidden = true
                }
            }
        }
    }
    
    func checkIfChatHasActiveCall() {
        
    }
    
    func configureTopBannerButtonForInProgressCall() {
        
    }
    
    func configureTopBannerButtonForActiveCall(_ call: MEGAChatCall) {
        showTopBannerButton()
        let title = chatRoom.isGroup ? AMLocalizedString("There is an active group call. Tap to join.", "Message shown in a chat room when there is an active group call"): AMLocalizedString("There is an active call. Tap to join.", "Message shown in a chat room when there is an active call")
        setTopBannerButton(title: title, color: UIColor.mnz_green00BFA5())
    }
    
    @objc func joinActiveCall() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { (granted) in
            if granted {
                self.openCallViewWithVideo(videoCall: false, active: true)
            } else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            }
        }
    }
}

extension ChatViewController : MEGAChatCallDelegate {
    func onChatCallUpdate(_ api: MEGAChatSdk!, call: MEGAChatCall!) {
        switch call.status {
        case .userNoPresent, .requestSent:
            configureTopBannerButtonForActiveCall(call)
        case .inProgress:
            configureTopBannerButtonForActiveCall(call)
        case .reconnecting:
            setTopBannerButton(title: AMLocalizedString("Reconnecting...", "Title shown when the user lost the connection in a call, and the app will try to reconnect the user again."), color: UIColor.mnz_orangeFFA500())
        case .destroyed:
            timer?.invalidate()
            hideTopBannerButton()
        default:
            return
        }
    }
}
