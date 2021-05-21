import UIKit

extension ChatViewController {
    func checkIfChatHasActiveCall() {
        guard chatRoom.ownPrivilege == .standard
                || chatRoom.ownPrivilege == .moderator
                || !MEGAReachabilityManager.isReachable(),
              let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId),
              call.status != .destroyed,
              call.status != .terminatingUserParticipation else {
            hideJoinButton()
            return
        }
        
        showJoinButton()
    }
    
    private func showJoinButton() {
        joinCallButton.isHidden = false
    }
    
    private func hideJoinButton() {
        joinCallButton.isHidden = true
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
        guard call.chatId == chatRoom.chatId else {
            return
        }
        
        switch call.status {
        case .userNoPresent, .inProgress:
            showJoinButton()
            configureNavigationBar()
        case .destroyed, .terminatingUserParticipation:
            configureNavigationBar()
            hideJoinButton()
        default:
            return
        }
        chatCall = call
    }
}
