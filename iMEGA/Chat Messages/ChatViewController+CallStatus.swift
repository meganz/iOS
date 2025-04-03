import MEGAL10n

extension ChatViewController {
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
    
    func configureStartOrJoinCallButton(title: String, hide: Bool) {
        startOrJoinCallButton.setTitle(spacePadding + title + spacePadding, for: .normal)
        startOrJoinCallButton.isHidden = hide
    }
    
    @objc func didTapStartOrJoinCallFloatingButton() {
        chatContentViewModel.dispatch(.startOrJoinFloatingButtonTapped)
    }
    
    @objc func didTapToReturnToCallBannerButton() {
        chatContentViewModel.dispatch(.returnToCallBannerButtonTapped)
    }
}
