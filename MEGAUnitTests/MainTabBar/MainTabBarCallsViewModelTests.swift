@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class MainTabBarCallsViewModelTests: XCTestCase {
    private let router = MockMainTabBarCallsRouter()

    func testCallUpdate_onCallUpdateInProgressAndBeingModerator_waitingRoomListenerExists() {
        let callUseCase = MockCallUseCase()
        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))

        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
    }
    
    func testCallUpdate_onCallUpdateJoining_callSessionListenerExists() {
        let callUseCase = MockCallUseCase()
        let callKitManager = MockCallKitManager()
        
        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity()),
            callKitManager: callKitManager
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .joining, changeType: .status))

        evaluate {
            viewModel.callSessionUpdateSubscription != nil  &&
            callKitManager.notifyStartCallToCallKit_CalledTimes == 1
        }
    }
    
    func testCallUpdate_onSessionUpdateRecordingStart_alertShouldBeShown() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()
        let callSessionUseCase = MockCallSessionUseCase()
        let callKitManager = MockCallKitManager()
        
        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            callSessionUseCase: callSessionUseCase,
            callKitManager: callKitManager
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .joining, changeType: .status))
        
        evaluate {
            viewModel.callSessionUpdateSubscription != nil &&
            callKitManager.notifyStartCallToCallKit_CalledTimes == 1
        }
        
        callSessionUseCase.callSessionUpdateSubject.send((ChatSessionEntity(changeType: .onRecording, onRecording: true), CallEntity()))
        
        evaluate { self.router.showScreenRecordingAlert_calledTimes == 1 }
    }
    
    func testJoinCall_onSessionInProgressIsRecording_alertShouldBeShown() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()
        let callSessionUseCase = MockCallSessionUseCase()
        let callKitManager = MockCallKitManager()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            callSessionUseCase: callSessionUseCase,
            callKitManager: callKitManager
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .joining, changeType: .status))
        
        evaluate {
            viewModel.callSessionUpdateSubscription != nil &&
            callKitManager.notifyStartCallToCallKit_CalledTimes == 1
        }
        
        callSessionUseCase.callSessionUpdateSubject.send((ChatSessionEntity(statusType: .inProgress, changeType: .status, onRecording: true), CallEntity()))
        
        evaluate { self.router.showScreenRecordingAlert_calledTimes == 1 }
    }
    
    func testJoinCall_onSessionInProgressIsRecording_alertShouldNotBeShown() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()
        let callSessionUseCase = MockCallSessionUseCase()
        let callKitManager = MockCallKitManager()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            callSessionUseCase: callSessionUseCase,
            callKitManager: callKitManager
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .joining, changeType: .status))
        
        evaluate {
            viewModel.callSessionUpdateSubscription != nil  &&
            callKitManager.notifyStartCallToCallKit_CalledTimes == 1
        }
        
        callSessionUseCase.callSessionUpdateSubject.send((ChatSessionEntity(statusType: .inProgress, changeType: .status, onRecording: false), CallEntity()))
        
        evaluate { self.router.showScreenRecordingAlert_calledTimes == 0 }
    }
    
    func testCallUpdate_onSessionUpdateRecordingStop_recordingNotificationShouldBeShown() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()
        let callSessionUseCase = MockCallSessionUseCase()
        let callKitManager = MockCallKitManager()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            callSessionUseCase: callSessionUseCase,
            callKitManager: callKitManager
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .joining, changeType: .status))
        
        evaluate {
            viewModel.callSessionUpdateSubscription != nil  &&
            callKitManager.notifyStartCallToCallKit_CalledTimes == 1
        }
        
        callSessionUseCase.callSessionUpdateSubject.send((ChatSessionEntity(changeType: .onRecording, onRecording: false), CallEntity()))
        
        evaluate { self.router.showScreenRecordingNotification_calledTimes == 1 }
    }

    func testCallUpdate_onCallUpdateInProgressAndNotBeingModerator_waitingRoomListenerNotExists() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))

        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription == nil
        }
    }
    
    func testCallUpdate_onCallUpdateInProgressAndWaitingRoomNotEnabled_waitingRoomListenerNotExists() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: false), peerPrivilege: .standard)
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))

        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription == nil
        }
    }
    
    func testCallUpdate_oneUserOnWaitingRoomAndBeingModerator_showOneUserAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [100])))

        evaluate {
            self.router.showOneUserWaitingRoomDialog_calledTimes == 1
        }
    }
    
    func testCallUpdate_severalUsersOnWaitingAndRoomBeingModerator_showSeveralUsersAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [100, 101])))

        evaluate {
            self.router.showSeveralUsersWaitingRoomDialog_calledTimes == 1
        }
    }
    
    func testCallUpdate_noUsersOnWaitingRoomAndBeingModerator_dismissAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [])))

        evaluate {
            self.router.dismissWaitingRoomDialog_calledTimes == 1
        }
    }
    
    func testCallUpdate_severalUsersOnWaitingAndRoomBeingModeratorAndCallChangeTypeWaitingRoomUsersAllow_shouldNotShowSeveralUsersAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(changeType: .waitingRoomUsersAllow, waitingRoom: WaitingRoomEntity(sessionClientIds: [100, 101])))

        evaluate {
            self.router.showSeveralUsersWaitingRoomDialog_calledTimes == 0
        }
    }
    
    func testCallUpdate_oneUserOnWaitingRoomAndBeingModeratorAndCallChangeTypeWaitingRoomUsersAllow_shouldNotShowOneUserAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel( 
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(changeType: .waitingRoomUsersAllow, waitingRoom: WaitingRoomEntity(sessionClientIds: [100])))

        evaluate {
            self.router.showOneUserWaitingRoomDialog_calledTimes == 0
        }
    }
    
    func testCallUpdate_callDestroyedUserIsCallerAndCallUINotVisible_shouldShowUpgradeToPro() {
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard)),
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity()),
            featureFlagProvider: MockFeatureFlagProvider(list: [.chatMonetization: true])
        )
        viewModel.isCallUIVisible = false
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit, isOwnClientCaller: true))

        evaluate {
            self.router.showUpgradeToProDialog_calledTimes == 1
        }
    }
    
    func testCallUpdate_callDestroyedUserIsCallerAndCallUIVisible_shouldNotShowUpgradeToPro() {
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard)),
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity()),
            featureFlagProvider: MockFeatureFlagProvider(list: [.chatMonetization: true])
        )
        viewModel.isCallUIVisible = true
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit, isOwnClientCaller: true))

        evaluate {
            self.router.showUpgradeToProDialog_calledTimes == 0
        }
    }
    
    func testCallUpdate_callDestroyedUserIsNotCaller_shouldNotShowUpgradeToPro() {
        let callUseCase = MockCallUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard)),
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity()),
            featureFlagProvider: MockFeatureFlagProvider(list: [.chatMonetization: true])
        )
        viewModel.isCallUIVisible = false
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit))

        evaluate {
            self.router.showUpgradeToProDialog_calledTimes == 0
        }
    }
    
    func testCallUpdate_callPlusWaitingRoomExceedLimit_AdmitButtonDisabled() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()
        
        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: [.chatMonetization: true])
        )
        
        callUseCase.callUpdateSubject.send(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(
            CallEntity(
                callLimits: .init(durationLimit: -1, maxUsers: 3, maxClientsPerUser: -1, maxClients: -1),
                numberOfParticipants: 3,
                waitingRoom: WaitingRoomEntity(sessionClientIds: [100, 101])
            )
        )
        
        evaluate {
            self.router.showSeveralUsersWaitingRoomDialog_calledTimes == 1
        }
        evaluate {
            self.router.shouldBlockAddingUsersToCall_received == [true]
        }
    }
    
    // MARK: - Private methods
    
    private func evaluate(expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 5)
    }
    
    private func makeMainTabBarCallsViewModel(
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        callUseCase: some CallUseCaseProtocol =  MockCallUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        callSessionUseCase: some CallSessionUseCaseProtocol = MockCallSessionUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        handleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callKitManager: some CallKitManagerProtocol = MockCallKitManager(),
        callManager: some CallManagerProtocol = MockCallManager(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> MainTabBarCallsViewModel {
        MainTabBarCallsViewModel(
            router: router,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            callSessionUseCase: callSessionUseCase, 
            accountUseCase: accountUseCase,
            handleUseCase: handleUseCase,
            callKitManager: callKitManager,
            callManager: callManager, 
            callUpdateFactory: CXCallUpdateFactory(builder: { CXCallUpdate() }),
            featureFlagProvider: featureFlagProvider
        )
    }
}

final class MockMainTabBarCallsRouter: MainTabBarCallsRouting {
    
    var showOneUserWaitingRoomDialog_calledTimes = 0
    var showSeveralUsersWaitingRoomDialog_calledTimes = 0
    var dismissWaitingRoomDialog_calledTimes = 0
    var showConfirmDenyAction_calledTimes = 0
    var showParticipantsJoinedTheCall_calledTimes = 0
    var showWaitingRoomListFor_calledTimes = 0
    var showScreenRecordingAlert_calledTimes = 0
    var showScreenRecordingNotification_calledTimes = 0
    var navigateToPrivacyPolice_calledTimes = 0
    var dismissCallUI_calledTimes = 0
    var showCallWillEndAlert_calledTimes = 0
    var showUpgradeToProDialog_calledTimes = 0
    var startCallUI_calledTimes = 0
    var shouldBlockAddingUsersToCall_received = [Bool]()

    func showOneUserWaitingRoomDialog(
        for username: String,
        chatName: String,
        isCallUIVisible: Bool,
        shouldUpdateDialog: Bool,
        shouldBlockAddingUsersToCall: Bool,
        admitAction: @escaping () -> Void,
        denyAction: @escaping () -> Void
    ) {
        shouldBlockAddingUsersToCall_received.append(shouldBlockAddingUsersToCall)
        showOneUserWaitingRoomDialog_calledTimes += 1
    }

    func showSeveralUsersWaitingRoomDialog(
        for participantsCount: Int,
        chatName: String,
        isCallUIVisible: Bool,
        shouldUpdateDialog: Bool,
        shouldBlockAddingUsersToCall: Bool,
        admitAction: @escaping () -> Void,
        seeWaitingRoomAction: @escaping () -> Void
    ) {
        shouldBlockAddingUsersToCall_received.append(shouldBlockAddingUsersToCall)
        showSeveralUsersWaitingRoomDialog_calledTimes += 1
    }
    
    func dismissWaitingRoomDialog(animated: Bool) {
        dismissWaitingRoomDialog_calledTimes += 1
    }

    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void, cancelDenyAction: @escaping () -> Void) {
        showConfirmDenyAction_calledTimes += 1
    }
    
    func showParticipantsJoinedTheCall(message: String) {
        showParticipantsJoinedTheCall_calledTimes += 1
    }
    
    func showWaitingRoomListFor(call: CallEntity, in chatRoom: ChatRoomEntity) {
        showWaitingRoomListFor_calledTimes += 1
    }
    
    func showScreenRecordingAlert(isCallUIVisible: Bool, acceptAction: @escaping (Bool) -> Void, learnMoreAction: @escaping () -> Void, leaveCallAction: @escaping () -> Void) {
        showScreenRecordingAlert_calledTimes += 1
    }
    
    func showScreenRecordingNotification(started: Bool, username: String) {
        showScreenRecordingNotification_calledTimes += 1
    }
    
    func navigateToPrivacyPolice() {
        navigateToPrivacyPolice_calledTimes += 1
    }
    
    func dismissCallUI() {
        dismissCallUI_calledTimes += 1
    }
    
    func showCallWillEndAlert(timeToEndCall: Double, isCallUIVisible: Bool) {
        showCallWillEndAlert_calledTimes += 1
    }
    
    func showUpgradeToProDialog(_ account: AccountDetailsEntity) {
        showUpgradeToProDialog_calledTimes += 1
    }
    
    func startCallUI(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool) {
        startCallUI_calledTimes += 1
    }
}
