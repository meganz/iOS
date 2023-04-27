import UIKit
import Combine
import MEGADomain
import MEGAData

extension ChatViewController {
    func initTimerForCall(_ call: CallEntity) {
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
    
    func showTapToReturnToCall(withTitle title: String) {
        tapToReturnToCallButton.setTitle(title, for: .normal)
        tapToReturnToCallButton.isHidden = false
    }
    
    func shouldEnableAudioVideoButtons(_ enable: Bool) {
        audioCallBarButtonItem.isEnabled = enable
        videoCallBarButtonItem.isEnabled = enable
    }
    
    func updateTapToReturnToCallLabel(withStartTime startTime: TimeInterval) {
        guard let initDuration = initDuration else { return }
        
        let time = Date().timeIntervalSince1970 - startTime + initDuration
        let title = Strings.Localizable.Chat.CallInProgress.tapToReturnToCall(time.timeString)
        showTapToReturnToCall(withTitle: title)
    }
    
    func tapToReturnToCallCleanup() {
        timer?.invalidate()
        tapToReturnToCallButton.isHidden = true
    }
    
    func startOrJoinCallCleanUp(callInProgress: Bool, scheduledMeetings: [ScheduledMeetingEntity]) {
        timer?.invalidate()
        
        if !chatRoom.isArchived && chatRoom.isMeeting && scheduledMeetings.isNotEmpty && !callInProgress {
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
    
    func showCallEndTimerIfNeeded(call: CallEntity) {
        guard MeetingContainerRouter.isAlreadyPresented == false,
              call.changeTye == .callComposition,
              call.numberOfParticipants == 1,
              call.participants.first == chatContentViewModel.userHandle else {
            
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
}

extension ChatViewController: MEGAChatCallDelegate {
    func onChatCallUpdate(_: MEGAChatSdk, call: MEGAChatCall) {
        chatContentViewModel.dispatch(.updateCall(call.toCallEntity()))
    }
}
