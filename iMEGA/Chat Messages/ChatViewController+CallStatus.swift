import UIKit

extension ChatViewController {
    
    func checkIfChatHasActiveCall() {
        if chatRoom.ownPrivilege == .standard || chatRoom.ownPrivilege == .moderator {
            if (MEGASdkManager.sharedMEGAChatSdk()?.hasCall(inChatRoom: chatRoom.chatId))!
                && MEGAReachabilityManager.isReachable() {
                let call = MEGASdkManager.sharedMEGAChatSdk()?.chatCall(forChatId: chatRoom.chatId)
                if !chatRoom.isGroup && call?.status == .destroyed {
                    return
                }
                if call?.status == .inProgress {
                    configureTopBannerButtonForInProgressCall(call!)
                } else if call?.status == .userNoPresent
                    || call?.status == .requestSent
                    || call?.status == .ringIn {
                    configureTopBannerButtonForActiveCall(call!)
                }
                showTopBannerButton()
            } else {
                hideTopBannerButton()
            }
        }
    }
    
    func setTopBannerButton(title: String, color: UIColor) {
        topBannerButton.backgroundColor = color
        topBannerButton.setTitle(title, for: .normal)
    }
    
    func showTopBannerButton() {
        if topBannerButton.isHidden {
            topBannerButton.isHidden = false
            self.view.layoutIfNeeded()

            topBannerButtonTopConstraint?.constant = 0
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func hideTopBannerButton() {
        if !topBannerButton.isHidden {
            self.view.layoutIfNeeded()

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
    
    func initTimerForCall(_ call: MEGAChatCall) {
        initDuration = TimeInterval(call.duration)
        if !(timer?.isValid ?? false) {
            
            let startTime = Date().timeIntervalSince1970
            let time = Date().timeIntervalSince1970 - startTime + self.initDuration!
            
            self.setTopBannerButton(title: String(format: AMLocalizedString("Touch to return to call %@", "Message shown in a chat room for a group call in progress displaying the duration of the call"), NSString.mnz_string(fromTimeInterval: time)), color:  UIColor.mnz_turquoise(for: self.traitCollection))
            timer = Timer(timeInterval: 1, repeats: true, block: { (timer) in
                if self.chatCall?.status == .reconnecting {
                    return
                }
                let time = Date().timeIntervalSince1970 - startTime + self.initDuration!

                self.setTopBannerButton(title: String(format: AMLocalizedString("Touch to return to call %@", "Message shown in a chat room for a group call in progress displaying the duration of the call"), NSString.mnz_string(fromTimeInterval: time)), color:  UIColor.mnz_turquoise(for: self.traitCollection))
            })
            RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        }
    }
    
    func configureTopBannerButtonForInProgressCall(_ call: MEGAChatCall) {
        if chatCall?.status == .reconnecting {
            setTopBannerButton(title: AMLocalizedString("You are back!", "Title shown when the user reconnect in a call."), color: UIColor.mnz_turquoise(for: traitCollection))
        }
        initTimerForCall(call)
    }
    
    func configureTopBannerButtonForActiveCall(_ call: MEGAChatCall) {
        let title = chatRoom.isGroup ? AMLocalizedString("There is an active group call. Tap to join.", "Message shown in a chat room when there is an active group call"): AMLocalizedString("There is an active call. Tap to join.", "Message shown in a chat room when there is an active call")
        setTopBannerButton(title: title, color: UIColor.mnz_turquoise(for: traitCollection))
        showTopBannerButton()
    }
    
    @objc func joinActiveCall() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { (granted) in
            if granted {
                self.timer?.invalidate()
                self.openCallViewWithVideo(videoCall: false)
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
            configureNavigationBar()
        case .inProgress:
            configureTopBannerButtonForInProgressCall(call)
        case .reconnecting:
            setTopBannerButton(title: AMLocalizedString("Reconnecting...", "Title shown when the user lost the connection in a call, and the app will try to reconnect the user again."), color: UIColor.systemOrange)
        case .destroyed:
            timer?.invalidate()
            configureNavigationBar()
            hideTopBannerButton()
        default:
            return
        }
        chatCall = call
    }
}
