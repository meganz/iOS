import Combine
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import UIKit

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
    
    func hideStartOrJoinCallButton(_ hide: Bool) {
        timer?.invalidate()
        
        startOrJoinCallButton.setTitle(spacePadding + Strings.Localizable.Meetings.Scheduled.ButtonOverlay.startMeeting + spacePadding, for: .normal)
        startOrJoinCallButton.isHidden = hide
    }
    
    @objc func didTapJoinCall() {
        guard !MEGAChatSdk.shared.mnz_existsActiveCall ||
                MEGAChatSdk.shared.isCallActive(forChatRoomId: chatRoom.chatId) else {
            MeetingAlreadyExistsAlert.show(presenter: self) { [weak self] in
                guard let self = self else { return }
                self.endActiveCallAndJoinCurrentChatroomCall()
            }
            return
        }
        
        joinCall()
    }
    
    @objc func didTapToReturnToCall() {
        guard !MEGAChatSdk.shared.mnz_existsActiveCall ||
                MEGAChatSdk.shared.isCallActive(forChatRoomId: chatRoom.chatId) else {
            MeetingAlreadyExistsAlert.show(presenter: self) { [weak self] in
                guard let self = self else { return }
                self.endActiveCallAndJoinCurrentChatroomCall()
            }
            return
        }
        
        joinCall()
    }
    
    private func endCall(_ call: CallEntity) {
        let callRepository = CallRepository(chatSdk: MEGAChatSdk.sharedChatSdk, callActionManager: CallActionManager.shared)
        CallUseCase(repository: callRepository).hangCall(for: call.callId)
        CallCoordinatorUseCase().endCall(call)
    }
    
    private func endActiveCallAndJoinCurrentChatroomCall() {
        if let activeCall = MEGAChatSdk.shared.firstActiveCall {
            endCall(activeCall.toCallEntity())
        }
        
        joinCall()
    }
    
    private func joinCall() {
        permissionRouter.audioPermission(modal: true, incomingCall: false) {[weak self] granted in
            guard let self else { return }
            if granted {
                timer?.invalidate()
                openCallViewWithVideo(videoCall: false, shouldRing: false)
            } else {
                permissionRouter.alertAudioPermission(incomingCall: false)
            }
        }
    }

    func subscribeToNoUserJoinedNotification() {
        let usecase = MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo)
        noUserJoinedSubscription = usecase
            .monitor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self,
                      MeetingContainerRouter.isAlreadyPresented == false,
                      let call = MEGAChatSdk.shared.chatCall(forChatId: self.chatRoom.chatId) else {
                    return
                }
                
                self.showCallEndDialog(withCall: call.toCallEntity())
            }
        
        self.meetingNoUserJoinedUseCase = usecase
    }
    
    func showCallEndTimerIfNeeded(call: CallEntity) {
        guard MeetingContainerRouter.isAlreadyPresented == false,
              call.changeType == .callComposition,
              call.numberOfParticipants == 1,
              call.participants.first == chatContentViewModel.userHandle else {
            
            if call.changeType == .callComposition, call.numberOfParticipants > 1 {
                removeEndCallDialogIfNeeded()
                cancelEndCallSubscription()
            }
            
            return
        }
        
        showCallEndDialog(withCall: call)
    }
    
    private func showCallEndDialog(withCall call: CallEntity) {
        let analyticsEventStatsUseCase = AnalyticsEventUseCase(repository: AnalyticsRepository(sdk: MEGASdk.sharedSdk))
        
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
            .sink { [weak self] _ in
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
