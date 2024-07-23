import CombineSchedulers
import ConcurrencyExtras
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock
import XCTest

final class CallControlsViewModelTests: XCTestCase {
    @MainActor func testEndCall_beingModeratorAndMoreThanOneParticipantInGroupCall_shouldShowHangOrEndCallDialog() async {
        let harness = Harness(chatType: .meeting, numberOfCallParticipants: 2)
        await harness.sut.endCallTapped()
        XCTAssertTrue(harness.showHangOrEndCallDialogShown())
    }
    
    @MainActor func testEndCall_beingModeratorAndOneParticipantInGroupCall_shouldEndCall() async {
        let harness = Harness(chatType: .meeting, numberOfCallParticipants: 1)
        await harness.sut.endCallTapped()
        XCTAssertTrue(harness.endCallNotifiedToCallManager())
    }
    
    @MainActor func testEndCall_inOneToOne_shouldEndCall() async {
        let harness = Harness(chatType: .oneToOne, numberOfCallParticipants: 1)
        await harness.sut.endCallTapped()
        XCTAssertTrue(harness.endCallNotifiedToCallManager())
    }
    
    @MainActor func testEndCall_notBeingModeratorAndMoreThanOneParticipantInGroupCall_shouldShowHangOrEndCallDialog() async {
        let harness = Harness(chatType: .meeting, isModerator: false, numberOfCallParticipants: 2)
        await harness.sut.endCallTapped()
        XCTAssertTrue(harness.endCallNotifiedToCallManager())
    }
    
    func testEnableSpeaker() {
        let harness = Harness(speakerEnabled: false)
        harness.sut.toggleSpeakerTapped()
        XCTAssertTrue(harness.enableLoudSpeakerCalled())
    }
    
    func testDisableSpeaker() {
        let harness = Harness(speakerEnabled: true)
        harness.sut.toggleSpeakerTapped()
        XCTAssertTrue(harness.disableLoudSpeakerCalled())
    }
    
    func testToggleMic_notGrantedAudioPermission_shouldShowPermissionAlert() async {
        let harness = Harness()
        await harness.toggleMicTapped()
        XCTAssertTrue(harness.showAudioPermissionAlert())
    }
    
    func testToggleMic_grantedAudioPermission_shouldShowPermissionAlert() async {
        let harness = Harness(permissionsAuthorised: true)
        await harness.toggleMicTapped()
        XCTAssertTrue(harness.muteCallNotifiedToCallManager())
    }
    
    func testEnableCamera_notGrantedVideoPermission_shouldShowPermissionAlert() async {
        let harness = Harness(cameraEnabled: false)
        await harness.toggleCameraTapped()
        XCTAssertTrue(harness.showVideoPermissionAlert())
    }
    
    func testEnableCamera_grantedVideoPermission_shouldShowPermissionAlert() async {
        let harness = Harness(permissionsAuthorised: true, cameraEnabled: false)
        await harness.toggleCameraTapped()
        XCTAssertTrue(harness.enableCameraCalled())
    }
    
    func testDisableCamera_grantedVideoPermission_shouldShowPermissionAlert() async {
        let harness = Harness(permissionsAuthorised: true, cameraEnabled: true)
        await harness.toggleCameraTapped()
        XCTAssertTrue(harness.disableCameraCalled())
    }
    
    func testSwitchCamera_cameraNotEnabled_shouldNotSwitchCamera() async {
        let harness = Harness(permissionsAuthorised: true, cameraEnabled: false)
        await harness.switchCameraTapped()
        XCTAssertFalse(harness.switchCameraCalled())
    }
    
    func testSwitchCamera_cameraEnabled_shouldNotSwitchCamera() async {
        let harness = Harness(permissionsAuthorised: true, cameraEnabled: true)
        await harness.switchCameraTapped()
        XCTAssertTrue(harness.switchCameraCalled())
    }
    
    func testAudioRouteChange_bluetoothConnected_shouldShowRouteView() {
        let harness = Harness(bluetoothAudioDeviceAvailable: true)
        harness.postAudioRouteChangeNotification()
        XCTAssertTrue(harness.sut.routeViewVisible)
    }
    
    func testAudioRouteChange_noBluetoothConnectedSpeakerEnabled_shouldShowSpeakerEnabled() {
        let harness = Harness(audioPortOutput: .builtInSpeaker, bluetoothAudioDeviceAvailable: false)
        harness.postAudioRouteChangeNotification()
        XCTAssertTrue(harness.sut.speakerEnabled)
        XCTAssertFalse(harness.sut.routeViewVisible)
    }
    
    func testAudioRouteChange_noBluetoothConnectedSpeakerDisabled_shouldShowSpeakerDisabled() {
        let harness = Harness(audioPortOutput: .builtInReceiver, bluetoothAudioDeviceAvailable: false)
        harness.postAudioRouteChangeNotification()
        XCTAssertFalse(harness.sut.speakerEnabled)
        XCTAssertFalse(harness.sut.routeViewVisible)
    }
                
    func testMoreButtonShow_OneToOneCall_NotShown() {
        let harness = Harness(chatType: .oneToOne)
        XCTAssertFalse(harness.sut.showMoreButton)
    }
    
    func testMoreButtonShow_notOneToOneCall_Shown() {
        let harness = Harness.withMoreButtonEnabled()
        XCTAssertTrue(harness.sut.showMoreButton)
    }
    
    func testMoreButtonTapped_HasCorrectActions_handRaised() async {
        let harness = Harness.withMoreButtonEnabled().raisedHand(true)
        await harness.sut.moreButtonTapped()
        let expected: [String] = [
            Strings.Localizable.Chat.Call.ContextMenu.switchToMainView,
            Strings.Localizable.Chat.Call.ContextMenu.lowerHand
        ]
        XCTAssertEqual(harness.presentedMenuActions.map(\.title), expected)
    }
    
    func testMoreButtonTapped_HasCorrectActions_handLowered() async {
        let harness = Harness.withMoreButtonEnabled().raisedHand(false)
        await harness.sut.moreButtonTapped()
        let expected: [String] = [
            Strings.Localizable.Chat.Call.ContextMenu.switchToMainView,
            Strings.Localizable.Chat.Call.ContextMenu.raiseHand
        ]
        XCTAssertEqual(harness.presentedMenuActions.map(\.title), expected)
    }
    
    func testMoreButtonTapped_HasCorrectActions_grid() async {
        let harness = Harness
            .withMoreButtonEnabled()
            .raisedHand(false)
            .currentLayout(.grid)
        await harness.sut.moreButtonTapped()
        
        let expected: [String] = [
            Strings.Localizable.Chat.Call.ContextMenu.switchToMainView,
            Strings.Localizable.Chat.Call.ContextMenu.raiseHand
        ]
        XCTAssertEqual(harness.presentedMenuActions.map(\.title), expected)
    }
    
    func testMoreButtonTapped_HasCorrectActions_speakerView() async {
        let harness = Harness
            .withMoreButtonEnabled()
            .raisedHand(false)
            .currentLayout(.speaker)
        await harness.sut.moreButtonTapped()
        
        let expected: [String] = [
            Strings.Localizable.Chat.Call.ContextMenu.switchToGrid,
            Strings.Localizable.Chat.Call.ContextMenu.raiseHand
        ]
        XCTAssertEqual(harness.presentedMenuActions.map(\.title), expected)
    }
    
    func testMoreButtonActionSwitchLayout_LayoutChannelUsed() async throws {
        let harness = Harness.withMoreButtonEnabled()
        await harness.sut.moreButtonTapped()
        let firstAction = try XCTUnwrap(harness.presentedMenuActions.first)
        firstAction.actionHandler()
        XCTAssertTrue(harness.layoutUpdates.isNotEmpty)
    }
    
    func testSwitchLayoutAction_Disabled_WhenLayoutChannelReturnFalse() async throws {
        let harness = Harness.withMoreButtonEnabled()
        harness.layoutUpdateChannel.layoutSwitchingEnabled = { false }
        let switchAction = await harness.moreAction(button: .switchLayout)
        XCTAssertFalse(switchAction.enabled)
    }
    
    func testSwitchLayoutAction_Enabled_WhenLayoutChannelReturnTrue() async throws {
        let harness = Harness.withMoreButtonEnabled()
        harness.layoutUpdateChannel.layoutSwitchingEnabled = { true }
        let switchAction = await harness.moreAction(button: .switchLayout)
        XCTAssertTrue(switchAction.enabled)
    }
    
    func testRaiseHandAction_TriggersCallUseCase() async throws {
        await withMainSerialExecutor {
            let harness = Harness.withMoreButtonEnabled().raisedHand(false)
            let raiseHandAction = await harness.moreAction(button: .raiseHand)
            raiseHandAction.actionHandler()
            await Task.yield()
            XCTAssertEqual(harness.callUseCase.raiseHand_CalledTimes, 1)
        }
    }
    
    func testLowerHandAction_TriggersCallUseCase() async throws {
        await withMainSerialExecutor {
            let harness = Harness.withMoreButtonEnabled().raisedHand(true)
            let raiseHandAction = await harness.moreAction(button: .raiseHand)
            raiseHandAction.actionHandler()
            await Task.yield()
            XCTAssertEqual(harness.callUseCase.lowerHand_CalledTimes, 1)
        }
    }
    
    func testRaiseHandAction_TriggersRaiseHandEvent() async throws {
        await withMainSerialExecutor {
            let harness = Harness.withMoreButtonEnabled().raisedHand(false)
            let raiseHandAction = await harness.moreAction(button: .raiseHand)
            raiseHandAction.actionHandler()
            await Task.yield()
            XCTAssertTrackedAnalyticsEventsEqual(
                harness.mockTracker.trackedEventIdentifiers,
                [CallRaiseHandEvent()]
            )
        }
    }
    
    func testLowerHandAction_TriggersLowerHandEvent() async throws {
        await withMainSerialExecutor {
            let harness = Harness.withMoreButtonEnabled().raisedHand(true)
            let raiseHandAction = await harness.moreAction(button: .raiseHand)
            raiseHandAction.actionHandler()
            await Task.yield()
            XCTAssertTrackedAnalyticsEventsEqual(
                harness.mockTracker.trackedEventIdentifiers,
                [CallLowerHandEvent()]
            )
        }
    }
    
    func testLocalAudioFlagUpdatedToMuted_shouldShowDisabledMicUI() {
        let harness = Harness()
        harness.localAudioFlagUpdated(enabled: false)
        XCTAssertFalse(harness.sut.micEnabled)
    }
    
    func testLocalAudioFlagUpdatedToUnmuted_shouldShowEnabledMicUI() {
        let harness = Harness()
        harness.localAudioFlagUpdated(enabled: true)
        XCTAssertTrue(harness.sut.micEnabled)
    }
    
    func testViewAppear_raiseHandBadgeNeverPresented_badgeMustBeShown() async {
        let harness = Harness().raiseHandBadge(presented: true)
        await harness.sut.checkRaiseHandBadge()
        XCTAssertTrue(harness.sut.showRaiseHandBadge)
    }
    
    func testViewAppear_raiseHandBadgeReachedMaxTimesPresented_badgeMustNotBeShown() async {
        let harness = Harness().raiseHandBadge(presented: false)
        await harness.sut.checkRaiseHandBadge()
        XCTAssertFalse(harness.sut.showRaiseHandBadge)
    }
    
    func testMoreButtonTapped_raiseHandBadgeNotReachedMaxTimesPresented_badgeMustBeShownAndIncrementCalled() async {
        let harness = Harness().raiseHandBadge(presented: true)
        await harness.sut.checkRaiseHandBadge()
        await harness.sut.moreButtonTapped()
        XCTAssertTrue(harness.sut.showRaiseHandBadge)
        XCTAssertTrue(harness.raiseHandBadgeStore.incrementRaiseHandBadgePresented_CallCount == 1)
    }
    
    func testMoreButtonTapped_raiseHandBadgeReachedMaxTimesPresented_badgeMustNotBeShownAndSaveRaiseHandPresentedNotCalled() async {
        await withMainSerialExecutor {
            let harness = Harness.withMoreButtonEnabled().raiseHandBadge(presented: false)
            await harness.sut.checkRaiseHandBadge()
            let raiseHandAction = await harness.moreAction(button: .raiseHand)
            raiseHandAction.actionHandler()
            await Task.yield()
            XCTAssertFalse(harness.sut.showRaiseHandBadge)
            XCTAssertTrue(harness.raiseHandBadgeStore.saveRaiseHandBadgeAsPresented_CallCount == 0)
        }
    }
    
    func testRaiseHandSignal_raiseHandBadgeNotReachedMaxTimesPresented_badgeMustBeShownAndSaveRaiseHandPresentedCalled() async {
        await withMainSerialExecutor {
            let harness = Harness.withMoreButtonEnabled().raiseHandBadge(presented: true)
            await harness.sut.checkRaiseHandBadge()
            let raiseHandAction = await harness.moreAction(button: .raiseHand)
            raiseHandAction.actionHandler()
            await Task.yield()
            XCTAssertTrue(harness.sut.showRaiseHandBadge)
            XCTAssertTrue(harness.raiseHandBadgeStore.saveRaiseHandBadgeAsPresented_CallCount == 1)
        }
    }
    
    class Harness {
        let sut: CallControlsViewModel
        let chatRoom: ChatRoomEntity
        let callUseCase: MockCallUseCase
        let containerViewModel: MeetingContainerViewModel
        let audioSessionUseCase: MockAudioSessionUseCase
        let router: MockMeetingFloatingPanelRouter
        let callManager: MockCallManager
        let localVideoUseCase: MockCallLocalVideoUseCase
        let notificationCenter: MockNotificationCenter
        let layoutUpdateChannel = ParticipantLayoutUpdateChannel()
        var presentedMenuActions: [ActionSheetAction] = []
        var layoutUpdates: [ParticipantsLayoutMode] = []
        let cameraSwitcher = MockCameraSwitcher()
        let raiseHandBadgeStore = MockRaiseHandBadgeStore()
        let mockTracker = MockTracker()
        
        init(
            chatType: ChatRoomEntity.ChatType = .meeting,
            isModerator: Bool = true,
            numberOfCallParticipants: Int = 1,
            permissionsAuthorised: Bool = false,
            speakerEnabled: Bool = false,
            cameraEnabled: Bool = false,
            audioPortOutput: AudioPort = .builtInReceiver,
            bluetoothAudioDeviceAvailable: Bool = false
        ) {
            self.chatRoom = ChatRoomEntity(ownPrivilege: isModerator ? .moderator : .standard, chatType: chatType)
            self.callUseCase = MockCallUseCase(call: CallEntity(numberOfParticipants: numberOfCallParticipants))
            
            self.containerViewModel = MeetingContainerViewModel(chatRoom: chatRoom, callUseCase: callUseCase)
            self.audioSessionUseCase = MockAudioSessionUseCase(isBluetoothAudioRouteAvailable: bluetoothAudioDeviceAvailable, currentSelectedAudioPort: audioPortOutput)
            self.router = MockMeetingFloatingPanelRouter()
            self.callManager = MockCallManager()
            self.localVideoUseCase = MockCallLocalVideoUseCase()
            self.notificationCenter = MockNotificationCenter()
            
            var menuPresenter: ([ActionSheetAction]) -> Void = { _ in }
            
            sut = CallControlsViewModel(
                router: router,
                scheduler: .immediate,
                menuPresenter: { actions in menuPresenter(actions) },
                chatRoom: chatRoom,
                callUseCase: callUseCase,
                localVideoUseCase: localVideoUseCase,
                containerViewModel: containerViewModel,
                audioSessionUseCase: audioSessionUseCase, 
                permissionHandler: MockDevicePermissionHandler(
                    photoAuthorization: .authorized,
                    audioAuthorized: permissionsAuthorised,
                    videoAuthorized: permissionsAuthorised
                ),
                callManager: callManager,
                notificationCenter: notificationCenter,
                audioRouteChangeNotificationName: .audioRouteChange,
                accountUseCase: MockAccountUseCase(currentUser: .testUser),
                layoutUpdateChannel: layoutUpdateChannel,
                cameraSwitcher: cameraSwitcher,
                raiseHandBadgeStoring: raiseHandBadgeStore,
                tracker: mockTracker
            )
            
            menuPresenter = { [weak self] in
                self?.presentedMenuActions = $0
            }
            
            layoutUpdateChannel.updateLayout = { [weak self] in
                self?.layoutUpdates.append($0)
            }
            
            sut.speakerEnabled = speakerEnabled
            sut.cameraEnabled = cameraEnabled
        }
        
        func showHangOrEndCallDialogShown() -> Bool {
            router.showHangOrEndCallDialog_calledTimes == 1
        }
        
        func endCallNotifiedToCallManager() -> Bool {
            callManager.endCall_CalledTimes == 1
        }
        
        func muteCallNotifiedToCallManager() -> Bool {
            callManager.muteCall_CalledTimes == 1
        }
        
        func enableLoudSpeakerCalled() -> Bool {
            audioSessionUseCase.enableLoudSpeaker_calledTimes == 1
        }
        
        func disableLoudSpeakerCalled() -> Bool {
            audioSessionUseCase.disableLoudSpeaker_calledTimes == 1
        }
        
        func toggleMicTapped() async {
            await sut.toggleMicTapped()
        }
        
        func showAudioPermissionAlert() -> Bool {
            router.audioPermissionError_calledTimes == 1
        }
        
        func toggleCameraTapped() async {
            await sut.toggleCameraTapped()
        }
        
        func showVideoPermissionAlert() -> Bool {
            router.videoPermissionError_calledTimes == 1
        }
        
        func enableCameraCalled() -> Bool {
            localVideoUseCase.enableLocalVideo_CalledTimes == 1
        }
        
        func disableCameraCalled() -> Bool {
            localVideoUseCase.disableLocalVideo_CalledTimes == 1
        }
        
        func switchCameraTapped() async {
            await sut.switchCameraTapped()
        }
        
        func switchCameraCalled() -> Bool {
            cameraSwitcher.switchCamera_CallCount == 1
        }
        
        func postAudioRouteChangeNotification() {
            notificationCenter.postAudioRouteChangeNotification()
        }
        
        static func withMoreButtonEnabled() -> Harness {
            Harness(chatType: .meeting)
        }
        
        func raisedHand(_ raised: Bool) -> Self {
            let list: [HandleEntity] = raised ? [123]: []
            callUseCase.call = CallEntity(raiseHandsList: list)
            return self
        }
        
        func raiseHandBadge(presented: Bool) -> Self {
            raiseHandBadgeStore.shouldPresentRaiseHandBadge = presented
            return self
        }
        
        func currentLayout(_ layout: ParticipantsLayoutMode) -> Self {
            layoutUpdateChannel.getCurrentLayout = { layout }
            return self
        }
        
        func moreActions() async -> [ActionSheetAction] {
            await sut.moreButtonTapped()
            return presentedMenuActions
        }
        
        enum MoreButton {
            case switchLayout
            case raiseHand
        }
        
        func moreAction(button: MoreButton) async -> ActionSheetAction {
            await sut.moreButtonTapped()
            switch button {
            case .switchLayout:
                return presentedMenuActions[0]
            case .raiseHand:
                return presentedMenuActions[1]
            }
        }
        
        func localAudioFlagUpdated(enabled: Bool) {
            callUseCase
                .callUpdateSubject
                .send(.localCameraEnabled(enabled))
        }
    }
}

class MockNotificationCenter: NotificationCenter {
    func postAudioRouteChangeNotification() {
        post(name: .audioRouteChange, object: nil)
    }
}

extension Notification.Name {
    static let audioRouteChange = Notification.Name("audioRouteChange")
}

extension UserEntity? {
    static var testUser: UserEntity? = UserEntity(
        email: "email",
        handle: 123,
        visibility: .unknown,
        changes: .firstname,
        changeSource: .implicitRequest,
        addedDate: .now
    )
}

extension CallEntity {
    static func localCameraEnabled(_ enabled: Bool) -> CallEntity {
        .init(
            status: .inProgress,
            changeType: .localAVFlags,
            hasLocalAudio: enabled
        )
    }
}
