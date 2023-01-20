import UIKit
import Combine
import MEGADomain

extension ChatViewController {
    func checkIfChatHasActiveCall() {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId),
              call.status != .destroyed,
              call.status != .terminatingUserParticipation else {
            tapToReturnToCallCleanup()
            startOrJoinCallCleanup(callInProgress: false)
            return
        }
        
        onCallUpdate(call)
    }

    private func initTimerForCall(_ call: MEGAChatCall) {
        initDuration = TimeInterval(call.duration)
        if !(timer?.isValid ?? false) {
            let startTime = Date().timeIntervalSince1970
            updateTapToReturnToCallLabel(withStartTime: startTime)
            
            timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self, self.chatCall?.status != .connecting else { return }
                self.updateTapToReturnToCallLabel(withStartTime: startTime)
            }
            
            RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
        }
    }
    
     func showStartOrJoinCallButton() {
         guard !chatRoom.isArchived else {
             return
         }
         
         if chatRoom.isMeeting {
             startOrJoinCallButton.setTitle(spacePadding + Strings.Localizable.Meetings.Scheduled.ButtonOverlay.joinMeeting + spacePadding, for: .normal)
         } else {
             startOrJoinCallButton.setTitle(spacePadding + Strings.Localizable.Chat.joinCall + spacePadding, for: .normal)
         }
         
        startOrJoinCallButton.isHidden = false
    }
    
    private func showTapToReturnToCall(withTitle title: String) {
        tapToReturnToCallButton.setTitle(title, for: .normal)
        tapToReturnToCallButton.isHidden = false
    }
    
    private func updateTapToReturnToCallLabel(withStartTime startTime: TimeInterval) {
        guard let initDuration = initDuration else { return }
        
        let time = Date().timeIntervalSince1970 - startTime + initDuration
        let title = Strings.Localizable.Chat.CallInProgress.tapToReturnToCall(NSString.mnz_string(fromTimeInterval: time))
        showTapToReturnToCall(withTitle: title)
    }
    
    internal func tapToReturnToCallCleanup() {
        timer?.invalidate()
        tapToReturnToCallButton.isHidden = true
    }
    
    internal func startOrJoinCallCleanup(callInProgress: Bool) {
        timer?.invalidate()
        if !chatRoom.isArchived && chatRoom.isMeeting && !callInProgress {
            startOrJoinCallButton.setTitle(spacePadding + Strings.Localizable.Meetings.Scheduled.ButtonOverlay.startMeeting + spacePadding, for: .normal)
            startOrJoinCallButton.isHidden = false
        } else {
            startOrJoinCallButton.isHidden = true
        }
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
    
    @objc func didTapToReturnToCall() {
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
            endCall(activeCall.toCallEntity())
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
        let usecase = MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo)
        noUserJoinedSubscription = usecase
            .monitor
            .receive(on: DispatchQueue.main)
            .sink() { [weak self] _ in
                guard let self = self,
                      MeetingContainerRouter.isAlreadyPresented == false,
                      let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: self.chatRoom.chatId) else {
                    return
                }
                
                self.showCallEndDialog(withCall: call.toCallEntity())
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
        let analyticsEventStatsUseCase = AnalyticsEventUseCase(repository: AnalyticsRepository(sdk: MEGASdkManager.sharedMEGASdk()))

        let endCallDialog = EndCallDialog { [weak self] in
            analyticsEventStatsUseCase.sendAnalyticsEvent(.meetings(.stayOnCallInNoParticipantsPopup))
            self?.cancelEndCallSubscription()
        } endCallAction: { [weak self] in
            analyticsEventStatsUseCase.sendAnalyticsEvent(.meetings(.endCallInNoParticipantsPopup))
            self?.endCall(call)
            self?.cancelEndCallSubscription()
        }

        self.endCallDialog = endCallDialog
        endCallDialog.show()
        
        endCallSubscription = Just(Void.self)
            .delay(for: .seconds(120), scheduler: RunLoop.main)
            .sink() { [weak self] _ in
                self?.tonePlayer.play(tone: .callEnded)
                analyticsEventStatsUseCase.sendAnalyticsEvent(.meetings(.endCallWhenEmptyCallTimeout))
                                
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
            tapToReturnToCallCleanup()
            startOrJoinCallCleanup(callInProgress: false)
            return
        }

        switch call.status {
        case .initial, .joining, .userNoPresent:
            startOrJoinCallCleanup(callInProgress: false)
            tapToReturnToCallCleanup()
            showStartOrJoinCallButton()
        case .inProgress:
            startOrJoinCallCleanup(callInProgress: true)
            initTimerForCall(call)
            showCallEndTimerIfNeeded(call: call.toCallEntity())
        case .connecting:
            showTapToReturnToCall(withTitle: Strings.Localizable.reconnecting)
        case .destroyed, .terminatingUserParticipation, .undefined:
            startOrJoinCallCleanup(callInProgress: false)
            tapToReturnToCallCleanup()
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
