import Foundation

extension GroupChatDetailsViewController {
    @objc func addChatCallDelegate() {
        MEGASdkManager.sharedMEGAChatSdk().add(self as MEGAChatCallDelegate)
    }
    
    @objc func removeChatCallDelegate() {
        MEGASdkManager.sharedMEGAChatSdk().remove(self as MEGAChatCallDelegate)
    }
    
    @objc func showEndCallForAll() {
        let endCallDialog = EndCallDialog(
            type: .endCallForAll,
            forceDarkMode: false,
            autodismiss: true
        ) { [weak self] in
            self?.endCallDialog = nil
        } endCallAction: { [weak self] in
            guard let self = self,
                  let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: self.chatRoom.chatId) else {
                return
            }
            
            MEGASdkManager.sharedMEGAChatSdk().endChatCall(call.callId)
            self.navigationController?.popViewController(animated: true)
        }
        
        endCallDialog.show()
        self.endCallDialog = endCallDialog
    }
}

extension GroupChatDetailsViewController: MEGAChatCallDelegate {
    public func onChatCallUpdate(_ api: MEGAChatSdk!, call: MEGAChatCall!) {
        guard call.chatId == self.chatRoom.chatId else { return }
        
        if call.status == .inProgress || call.status == .terminatingUserParticipation{
            self.reloadData()
        }
    }
}
