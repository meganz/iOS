import UIKit

extension ChatViewController {
    func checkIfChatHasActiveCall() {
        if chatRoom.ownPrivilege == .standard || chatRoom.ownPrivilege == .moderator {
            if (MEGASdkManager.sharedMEGAChatSdk().hasCall(inChatRoom: chatRoom.chatId)),
                MEGAReachabilityManager.isReachable() {
                guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else {
                    return
                }
                if !chatRoom.isGroup && call.status == .destroyed {
                    return
                }
                if MEGASdkManager.sharedMEGAChatSdk().chatCalls(withState: .inProgress)?.size == 1 && call.status != .inProgress {
                    self.hideJoinButton()
                } else {
                    if call.status == .inProgress {
                        configureTopBannerButtonForInProgressCall(call)
                    } else if call.status == .userNoPresent || call.isRinging {
                        configureTopBannerButtonForActiveCall(call)
//                    } else if call?.status == .reconnecting {
//                        setTopBannerButton(title: NSLocalizedString("Reconnecting...", comment: "Title shown when the user lost the connection in a call, and the app will try to reconnect the user again."), color: UIColor.systemOrange)
//                        showTopBannerButton()
                    }
//                    } else if call?.status == .reconnecting {
//                        setTopBannerButton(title: NSLocalizedString("Reconnecting...", comment: "Title shown when the user lost the connection in a call, and the app will try to reconnect the user again."), color: UIColor.systemOrange)
//                        showTopBannerButton()
//                    }
                }
            } else {
                hideJoinButton()
            }
        }
    }
    
    private func showJoinButton() {
        joinCallButton.isHidden = false
    }
    
    private func hideJoinButton() {
        joinCallButton.isHidden = true
    }

//    private func initTimerForCall(_ call: MEGAChatCall) {
//        initDuration = TimeInterval(call.duration)
//        if let initDuration = initDuration, !(timer?.isValid ?? false) {
//            let bgColor = UIColor.mnz_turquoise(for: traitCollection)
//            topBannerView.backgroundColor = bgColor
//
//            let startTime = Date().timeIntervalSince1970
//            let time = Date().timeIntervalSince1970 - startTime + initDuration
//
//            timer = Timer(timeInterval: 1, repeats: true, block: { _ in
////                if self.chatCall?.status == .reconnecting {
////                    return
////                }
//                let time = Date().timeIntervalSince1970 - startTime + initDuration
//
//            })
//            RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
//        }
//    }

    private func configureTopBannerButtonForInProgressCall(_ call: MEGAChatCall) {
//        if chatCall?.status == .reconnecting {
//            setTopBannerButton(title: NSLocalizedString("You are back!", comment: "Title shown when the user reconnect in a call."), color: UIColor.mnz_turquoise(for: traitCollection))
//        }
//        initTimerForCall(call)
        showJoinButton()
    }

    private func configureTopBannerButtonForActiveCall(_: MEGAChatCall) {
        let title = chatRoom.isGroup ? NSLocalizedString("There is an active group call. Tap to join.", comment: "Message shown in a chat room when there is an active group call") : NSLocalizedString("Tap to return to call", comment: "Message shown in a chat room for a one on one call")
        showJoinButton()
    }

    @objc func didTapJoinCall() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { granted in
            if granted {
                self.timer?.invalidate()
                self.openCallViewWithVideo(videoCall: false)
            } else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            }
        }
    }
}

extension ChatViewController: MEGAChatCallDelegate {
    func onChatCallUpdate(_: MEGAChatSdk!, call: MEGAChatCall!) {
        if call.chatId != chatRoom.chatId {
            return
        }
        switch call.status {
        case .userNoPresent:
            configureTopBannerButtonForActiveCall(call)
            configureNavigationBar()
        case .inProgress:
            configureTopBannerButtonForInProgressCall(call)
//        case .reconnecting:
//            setTopBannerButton(title: NSLocalizedString("Reconnecting...", comment: "Title shown when the user lost the connection in a call, and the app will try to reconnect the user again."), color: UIColor.systemOrange)
        case .destroyed:
            configureNavigationBar()
            hideJoinButton()
        default:
            return
        }
        chatCall = call
    }
}
