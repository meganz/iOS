@testable import MEGA
import MEGADomain
import XCTest

final class MockMeetingContainerRouter: MeetingContainerRouting {
    
    var floatingPanelShown: Bool = false
    
    var showMeetingUI_calledTimes = 0
    var dismiss_calledTimes = 0
    var toggleFloatingPanel_CalledTimes = 0
    var showEndMeetingOptions_calledTimes = 0
    var showOptionsMenu_calledTimes = 0
    var shareLink_calledTimes = 0
    var renameChat_calledTimes = 0
    var showMeetingError_calledTimes = 0
    var enableSpeaker_calledTimes = 0
    var displayParticipantInMainView_calledTimes = 0
    var didDisplayParticipantInMainView_calledTimes = 0
    var didSwitchToGridView_calledTimes = 0
    var didShowEndDialog_calledTimes = 0
    var removeEndDialog_calledTimes = 0
    var showJoinMegaScreen_calledTimes = 0
    var showHangOrEndCallDialog_calledTimes = 0
    var selectWaitingRoomList_calledTimes = 0
    var showScreenShareWarning_calledTimes = 0
    var showMutedMessage_calledTimes = 0
    var showProtocolErrorAlert_calledTimes = 0
    var showUsersLimitErrorAlert_calledTimes = 0
    var showCallWillEndAlert_calledTimes = 0
    var showUpgradeToProDialog_calledTimes = 0
    
    func showMeetingUI(containerViewModel: MeetingContainerViewModel) {
        showMeetingUI_calledTimes += 1
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        toggleFloatingPanel_CalledTimes += 1
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        dismiss_calledTimes += 1
        completion?()
    }
    
    func showEndMeetingOptions(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel, sender: UIButton) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel) {
        showEndMeetingOptions_calledTimes += 1
    }
    
    func showShareChatLinkActivity(presenter: UIViewController?, sender: AnyObject, link: String, metadataItemSource: ChatLinkPresentationItemSource, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        shareLink_calledTimes += 1
    }
    
    func renameChat() {
        renameChat_calledTimes += 1
    }
    
    func showShareMeetingError() {
        showMeetingError_calledTimes += 1
    }
    
    func enableSpeaker(_ enable: Bool) {
        enableSpeaker_calledTimes += 1
    }
    
    func displayParticipantInMainView(_ participant: CallParticipantEntity) {
        displayParticipantInMainView_calledTimes += 1
    }
    
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity) {
        didDisplayParticipantInMainView_calledTimes += 1
    }
    
    func didSwitchToGridView() {
        didSwitchToGridView_calledTimes += 1
    }
    
    func showEndCallDialog(endCallCompletion: @escaping () -> Void, stayOnCallCompletion: (() -> Void)?) {
        didShowEndDialog_calledTimes += 1
    }
    
    func removeEndCallDialog(finishCountDown: Bool, completion: (() -> Void)?) {
        removeEndDialog_calledTimes += 1
    }
    
    func showJoinMegaScreen() {
        showJoinMegaScreen_calledTimes += 1
    }
    
    func showHangOrEndCallDialog(containerViewModel: MeetingContainerViewModel) {
        showHangOrEndCallDialog_calledTimes += 1
    }
    
    func selectWaitingRoomList(containerViewModel: MeetingContainerViewModel) {
        selectWaitingRoomList_calledTimes += 1
    }
    
    func showScreenShareWarning() {
        showScreenShareWarning_calledTimes += 1
    }
    
    func showMutedMessage(by name: String) {
        showMutedMessage_calledTimes += 1
    }
    
    func showProtocolErrorAlert() {
        showProtocolErrorAlert_calledTimes += 1
    }
    
    func showUsersLimitErrorAlert() {
        showUsersLimitErrorAlert_calledTimes += 1
    }
    
    func showCallWillEndAlert(timeToEndCall: Double, completion: ((Double) -> Void)?) {
        showCallWillEndAlert_calledTimes += 1
    }
    
    func showUpgradeToProDialog(_ account: AccountDetailsEntity) {
        showUpgradeToProDialog_calledTimes += 1
    }
    
    func transitionToLongForm() { }
    
    func showFloatingPanelIfNeeded(
        containerViewModel: MeetingContainerViewModel,
        completion: @escaping () -> Void
    ) {}
    
    func hideSnackBar() { }
}
