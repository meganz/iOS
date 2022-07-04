import UIKit
import Combine

extension ChatViewController {
    var joinCallString: String {
        return Strings.Localizable.Chat.joinCall
    }
    
    func checkIfChatHasActiveCall() {
        guard chatRoom.ownPrivilege == .standard
                || chatRoom.ownPrivilege == .moderator
                || !MEGAReachabilityManager.isReachable(),
              let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId),
              call.status != .destroyed,
              call.status != .terminatingUserParticipation else {
            joinCallCleanup()
            return
        }
        
        onCallUpdate(call)
    }

    private func initTimerForCall(_ call: MEGAChatCall) {
        initDuration = TimeInterval(call.duration)
        if !(timer?.isValid ?? false) {
            let startTime = Date().timeIntervalSince1970
            updateJoinCallLabel(withStartTime: startTime)
            
            timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self, self.chatCall?.status != .connecting else { return }
                self.updateJoinCallLabel(withStartTime: startTime)
            }
            
            RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        }
    }
    
    private func showJoinCall(withTitle title: String) {
        let spacePadding = "   "
        joinCallButton.setTitle(spacePadding + title + spacePadding, for: .normal)
        joinCallButton.isHidden = false
    }
    
    private func updateJoinCallLabel(withStartTime startTime: TimeInterval) {
        guard let initDuration = initDuration else { return }
        
        let time = Date().timeIntervalSince1970 - startTime + initDuration
        let title = Strings.Localizable.touchToReturnToCall(NSString.mnz_string(fromTimeInterval: time))
        showJoinCall(withTitle: title)
    }
    
    private func joinCallCleanup() {
        timer?.invalidate()
        joinCallButton.isHidden = true
    }
        
    @objc func didTapJoinCall() {
        guard !MEGASdkManager.sharedMEGAChatSdk().mnz_existsActiveCall ||
                MEGASdkManager.sharedMEGAChatSdk().isCallActive(forChatRoomId: chatRoom.chatId) else {
            MeetingAlreadyExistsAlert.show(presenter: self) { [weak self] in
                guard let self = self else { return }
                self.endActiveCallAndJoinCurrentChatroomCall()
            }
            return
        }
        
        joinCall()
    }
    
    private func endCall(_ call: CallEntity) {
        let callRepository = CallRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk(), callActionManager: CallActionManager.shared)
        CallUseCase(repository: callRepository).hangCall(for: call.callId)
        CallCoordinatorUseCase().endCall(call)
    }
    
    private func endActiveCallAndJoinCurrentChatroomCall() {
        if let activeCall = MEGASdkManager.sharedMEGAChatSdk().firstActiveCall {
            endCall(CallEntity(with: activeCall))
        }
        
        joinCall()
    }
    
    private func joinCall() {
        DevicePermissionsHelper.audioPermissionModal(true, forIncomingCall: false) { granted in
            if granted {
                self.timer?.invalidate()
                self.openCallViewWithVideo(videoCall: false)
            } else {
                DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
            }
        }
    }
    
    func subscribeToNoUserJoinedNotification() {
        let usecase = MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.newRepo)
        noUserJoinedSubscription = usecase
            .monitor
            .receive(on: DispatchQueue.main)
            .sink() { [weak self] _ in
                guard let self = self,
                      MeetingContainerRouter.isAlreadyPresented == false,
                      let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: self.chatRoom.chatId) else {
                    return
                }
                
                self.showCallEndDialog(withCall: CallEntity(with: call))
            }
        
        self.meetingNoUserJoinedUseCase = usecase
    }
    
    private func showCallEndTimerIfNeeded(call: CallEntity) {
        guard MeetingContainerRouter.isAlreadyPresented == false,
              call.changeTye == .callComposition,
              call.numberOfParticipants == 1,
              call.participants.first == MEGASdkManager.sharedMEGAChatSdk().myUserHandle else {
            
            if call.changeTye == .callComposition, call.numberOfParticipants > 1 {
                removeEndCallDialogIfNeeded()
                cancelEndCallSubscription()
            }
            
            return
        }
        
        showCallEndDialog(withCall: call)
    }
    
    private func showCallEndDialog(withCall call: CallEntity) {
        let endCallDialog = EndCallDialog { [weak self] in
            self?.cancelEndCallSubscription()
        } endCallAction: { [weak self] in
            self?.endCall(call)
            self?.cancelEndCallSubscription()
        }

        self.endCallDialog = endCallDialog
        endCallDialog.show()
        
        endCallSubscription = Just(Void.self)
            .delay(for: .seconds(120), scheduler: RunLoop.main)
            .sink() { [weak self] _ in
                self?.tonePlayer.play(tone: .callEnded)
                
                // When ending call, CallKit decativation will interupt playing of tone.
                // Adding a delay of 0.7 seconds so there is enough time to play the tone
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self?.removeEndCallDialogIfNeeded()
                    self?.endCall(call)
                    self?.endCallSubscription = nil
                }
            }
    }
    
    private func cancelEndCallSubscription() {
        endCallSubscription?.cancel()
        endCallSubscription = nil
    }
    
    private func removeEndCallDialogIfNeeded() {
        guard let endCallDialog = endCallDialog else { return }
        
        endCallDialog.dismiss()
        self.endCallDialog = nil
    }
    
    private func onCallUpdate(_ call: MEGAChatCall) {
        guard call.chatId == chatRoom.chatId else {
            return
        }
        
        configureNavigationBar()
        chatCall = call

        guard MEGASdkManager.sharedMEGAChatSdk().chatConnectionState(chatRoom.chatId) == .online else {
            joinCallCleanup()
            return
        }

        switch call.status {
        case .initial, .joining, .userNoPresent:
            joinCallCleanup()
            showJoinCall(withTitle: joinCallString)
        case .inProgress:
            initTimerForCall(call)
            showCallEndTimerIfNeeded(call: CallEntity(with: call))
        case .connecting:
            showJoinCall(withTitle: Strings.Localizable.reconnecting)
        case .destroyed, .terminatingUserParticipation, .undefined:
            joinCallCleanup()
        default:
            return
        }
    }
}

extension ChatViewController: MEGAChatCallDelegate {
    func onChatCallUpdate(_: MEGAChatSdk!, call: MEGAChatCall!) {
        onCallUpdate(call)
    }
}
