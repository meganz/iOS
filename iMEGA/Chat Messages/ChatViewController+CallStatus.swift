import UIKit

extension ChatViewController {
    func checkIfChatHasActiveCall() {
        if chatRoom.ownPrivilege == .standard || chatRoom.ownPrivilege == .moderator {
            if (MEGASdkManager.sharedMEGAChatSdk().hasCall(inChatRoom: chatRoom.chatId)),
                MEGAReachabilityManager.isReachable() {
                let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId)
                if !chatRoom.isGroup && call?.status == .destroyed {
                    return
                }
                if MEGASdkManager.sharedMEGAChatSdk().chatCalls(withState: .inProgress)?.size == 1 && call?.status != .inProgress {
                    self.hideTopBanner()
                } else {
                    if call?.status == .inProgress {
                        configureTopBannerForInProgressCall(call!)
                    } else if call?.status == .userNoPresent
                                || call?.status == .requestSent
                                || call?.status == .ringIn {
                        configureTopBannerForActiveCall(call!)
                    } else if call?.status == .reconnecting {
                        configureTopBannerForReconnecting()
                        showTopBanner()
                    }
                }
            } else {
                hideTopBanner()
            }
        }
    }

    private func showTopBanner() {
        if topBannerView.isHidden {
            topBannerView.isHidden = false
            
            topBannerViewTopConstraint?.constant = 0
            view.layoutIfNeeded()
        }
    }

    private func hideTopBanner() {
        if !topBannerView.isHidden {
            UIView.animate(withDuration: 0.5, animations: {
                self.topBannerViewTopConstraint?.constant = -44
                self.view.layoutIfNeeded()
            }) { finished in
                if finished {
                    self.topBannerView.isHidden = true
                }
            }
        }
        
        timer?.invalidate()
    }

    private func initTimerForCall(_ call: MEGAChatCall) {
        initDuration = TimeInterval(call.duration)
        if let initDuration = initDuration, !(timer?.isValid ?? false) {
            let bgColor = UIColor.mnz_turquoise(for: traitCollection)
            topBannerView.backgroundColor = bgColor
            
            let startTime = Date().timeIntervalSince1970
            let time = Date().timeIntervalSince1970 - startTime + initDuration
            let title = String(format: NSLocalizedString("Touch to return to call %@", comment: "Message shown in a chat room for a group call in progress displaying the duration of the call"), NSString.mnz_string(fromTimeInterval: time))
            topBannerLabel?.text = title
            manageCallIndicators()
            
            timer = Timer(timeInterval: 1, repeats: true, block: { _ in 
                if self.chatCall?.status == .reconnecting {
                    return
                }
                
                self.topBannerView.backgroundColor = bgColor
                let time = Date().timeIntervalSince1970 - startTime + initDuration
                let title = String(format: NSLocalizedString("Touch to return to call %@", comment: "Message shown in a chat room for a group call in progress displaying the duration of the call"), NSString.mnz_string(fromTimeInterval: time))
                self.topBannerLabel?.text = title
                
                self.manageCallIndicators()
            })
            RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        }
    }

    private func configureTopBannerForInProgressCall(_ call: MEGAChatCall) {
        if chatCall?.status == .reconnecting {
            topBannerLabel?.text = NSLocalizedString("You are back!", comment: "Title shown when the user reconnect in a call.")
            topBannerView.backgroundColor = UIColor.mnz_turquoise(for: traitCollection)
            topBannerMicrophoneMuted?.isHidden = true
            topBannerVideoEnabled?.isHidden = true
        }
        initTimerForCall(call)
        showTopBanner()
    }

    private func configureTopBannerForActiveCall(_: MEGAChatCall) {
        let title = chatRoom.isGroup ? NSLocalizedString("There is an active group call. Tap to join.", comment: "Message shown in a chat room when there is an active group call") : NSLocalizedString("Tap to return to call", comment: "Message shown in a chat room for a one on one call")
        topBannerLabel?.text = title
        topBannerView.backgroundColor = UIColor.mnz_turquoise(for: traitCollection)
        topBannerMicrophoneMuted?.isHidden = true
        topBannerVideoEnabled?.isHidden = true
        
        showTopBanner()
    }
    
    private func configureTopBannerForReconnecting() {
        topBannerLabel?.text = NSLocalizedString("Reconnecting...", comment: "Title shown when the user lost the connection in a call, and the app will try to reconnect the user again.")
        topBannerView.backgroundColor =  UIColor.systemOrange
        topBannerMicrophoneMuted?.isHidden = true
        topBannerVideoEnabled?.isHidden = true
    }

    @objc func joinActiveCall() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { granted in
            if granted {
                self.timer?.invalidate()
                self.openCallViewWithVideo(videoCall: false)
            } else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            }
        }
    }
    
    private func manageCallIndicators() {
        var microphoneMuted = false
        var videoEnabled = false
        if chatRoom.isGroup {
            microphoneMuted = !UserDefaults.standard.bool(forKey: "groupCallLocalAudio")
            videoEnabled = UserDefaults.standard.bool(forKey: "groupCallLocalVideo")
        } else {
            microphoneMuted = UserDefaults.standard.bool(forKey: "oneOnOneCallLocalAudio")
            videoEnabled = UserDefaults.standard.bool(forKey: "oneOnOneCallLocalVideo")
        }
        topBannerMicrophoneMuted?.isHidden = !microphoneMuted
        topBannerVideoEnabled?.isHidden = !videoEnabled
        
        if microphoneMuted || videoEnabled {
            topBannerLabel?.text = (topBannerLabel?.text ?? "") + " •"
        }
    }
}

extension ChatViewController: MEGAChatCallDelegate {
    func onChatCallUpdate(_: MEGAChatSdk!, call: MEGAChatCall!) {
        if call.chatId != chatRoom.chatId {
            return
        }
        switch call.status {
        case .userNoPresent, .requestSent:
            configureTopBannerForActiveCall(call)
            configureNavigationBar()
        case .inProgress:
            configureTopBannerForInProgressCall(call)
        case .reconnecting:
            configureTopBannerForReconnecting()
        case .destroyed:
            configureNavigationBar()
            hideTopBanner()
        default:
            return
        }
        chatCall = call
    }
}
