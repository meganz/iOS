import MEGAL10n

extension ChatViewController {
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
    
    func tapToReturnToCallCleanup() {
        tapToReturnToCallButton.isHidden = true
    }
    
    func hideStartOrJoinCallButton(_ hide: Bool) {        
        startOrJoinCallButton.setTitle(spacePadding + Strings.Localizable.Meetings.Scheduled.ButtonOverlay.startMeeting + spacePadding, for: .normal)
        startOrJoinCallButton.isHidden = hide
    }
    
    @objc func didTapStartOrJoinCallFloatingButton() {
        chatContentViewModel.dispatch(.startOrJoinFloatingButtonTapped)
    }
    
    @objc func didTapToReturnToCallBannerButton() {
        chatContentViewModel.dispatch(.returnToCallBannerButtonTapped)
    }
}
