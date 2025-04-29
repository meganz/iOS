import CallKit
@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import XCTest

class MockCXCallUpdate: CXCallUpdate { }

final class CallsCoordinatorTests: XCTestCase {
    
    class Harness {
        let sut: CallsCoordinator
        let chatRoomUseCase: MockChatRoomUseCase
        let callUseCase: MockCallUseCase
        let callUpdateUseCase: MockCallUpdateUseCase
        let audioSessionUseCase: MockAudioSessionUseCase
        let callsManager = MockCallsManager()
        let callKitProviderDelegateFactory = MockCallKitProviderDelegateFactory()
        let meetingNoUserJoinedUseCase = MockMeetingNoUserJoinedUseCase()
        
        @MainActor
        init(
            chatRoomEntity: ChatRoomEntity? = nil,
            call: CallEntity? = nil
        ) {
            chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
            callUseCase = MockCallUseCase(call: call)
            callUpdateUseCase = MockCallUpdateUseCase()
            audioSessionUseCase = MockAudioSessionUseCase()
            sut = CallsCoordinator(
                callUseCase: callUseCase,
                callUpdateUseCase: callUpdateUseCase,
                chatRoomUseCase: chatRoomUseCase,
                chatUseCase: MockChatUseCase(myUserHandle: 101),
                sessionUpdateUseCase: MockSessionUpdateUseCase(),
                noUserJoinedUseCase: meetingNoUserJoinedUseCase,
                captureDeviceUseCase: MockCaptureDeviceUseCase(),
                audioSessionUseCase: audioSessionUseCase,
                callsManager: callsManager,
                uuidFactory: { .testUUID }
            )
        }
        
        @MainActor
        static func withOutgoingCall(in chatRoomEntity: ChatRoomEntity) -> Harness {
            let harness = Harness(chatRoomEntity: .testChatRoomEntity)
            harness.setupProviderDelegate()
            harness.callsManager.addCall(CallActionSync(chatRoom: .testChatRoomEntity), withUUID: .testUUID)
            harness.callsManager.callForUUIDToReturn = CallActionSync(chatRoom: .testChatRoomEntity)
            return harness
        }
            
        func setupProviderDelegate() {
            sut.setupProviderDelegate(callKitProviderDelegateFactory.delegate)
        }
    }
    
    @MainActor
    func testReportIncomingCall_UnknownCall_DoesNothing() {
        let harness = Harness()
        harness.sut.reportIncomingCall(in: 123, completion: {})
    }
    
    @MainActor
    func testReportIncomingCall_NewCall_ReportsToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.setupProviderDelegate()
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callsManager.incomingCalls, [.init(uuid: .testUUID, chatRoom: .testChatRoomEntity)])
    }
    
    @MainActor
    func testReportIncomingCall_ExistingCall_DoesNotReportAgainToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.callsManager.addCall(CallActionSync(chatRoom: .testChatRoomEntity), withUUID: .testUUID) // simulating existing call
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callsManager.addCall_CalledTimes, 1)
    }
    
    @MainActor
    func testReportIncomingCall_ExistingCall_ProviderDelegateCalled_CompletionTriggered() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.setupProviderDelegate()
        var completionCalled = false
        harness.callsManager.addCall(CallActionSync(chatRoom: .testChatRoomEntity), withUUID: .testUUID) // simulating existing call
        harness.sut.reportIncomingCall(in: 123, completion: { completionCalled = true })
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.reportNewIncomingCall_calledTimes, 1)
        XCTAssertTrue(completionCalled)
    }
    
    @MainActor
    func testReportIncomingCall_NewCall_ProviderDelegateCalled_CompletionTriggered() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.setupProviderDelegate()
        var completionCalled = false
        harness.sut.reportIncomingCall(in: 123, completion: { completionCalled = true })
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.reportNewIncomingCall_calledTimes, 1)
        XCTAssertTrue(completionCalled)
    }
    
    @MainActor
    func testReportIncomingCall_CallExistsInChatUserIsParticipating_DoesNotReportToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .inProgress))
        harness.setupProviderDelegate()
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callsManager.incomingCalls, [])
    }
    
    @MainActor
    func testReportIncomingCall_CallExistsInChatUserIsNotParticipating_ReportToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .userNoPresent))
        harness.setupProviderDelegate()
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callsManager.incomingCalls, [.init(uuid: .testUUID, chatRoom: .testChatRoomEntity)])
    }
    
    @MainActor
    func testReportIncomingCall_UserHasAlreadyAnsweredInOtherDevice_ShouldReportEndCall() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .userNoPresent, participants: [100, 101]))
        harness.setupProviderDelegate()
        harness.sut.reportIncomingCall(in: 123, completion: { })
        XCTAssertEqual(harness.callsManager.removeCall_CalledTimes, 1)
    }
    
    @MainActor
    func testEndCall_UserNotPresentOneToOneChat_ShouldHangCall() async {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .userNoPresent, participants: [100]))
        _ = await harness.sut.endCall(.speakerEnabled(false))
        
        XCTAssertEqual(harness.callUseCase.hangCall_CalledTimes, 1)
    }
    
    @MainActor
    func testEndCall_UserNotPresentGroupChat_ShouldNotHangCall() async {
        let chatRoom = ChatRoomEntity(chatType: .group)
        let harness = Harness(chatRoomEntity: chatRoom, call: CallEntity(status: .userNoPresent, participants: [100]))
        _ = await harness.sut.endCall(CallActionSync(chatRoom: chatRoom))
        
        XCTAssertEqual(harness.callUseCase.hangCall_CalledTimes, 0)
    }
    
    @MainActor
    func testOnChatCallUpdate_StopRingingAndUserNotParticipant_ShouldReportEndCall() async throws {
        let expectation = expectation(description: #function)
        let initialCall = CallEntity(
            status: .userNoPresent,
            participants: [100]
        )
        let harness = Harness(
            chatRoomEntity: .testChatRoomEntity,
            call: initialCall
        )
        harness.setupProviderDelegate()

        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.reportNewIncomingCall_calledTimes, 1)

        let callUpdate = CallEntity(
            status: .userNoPresent,
            changeType: .ringingStatus,
            isRinging: false,
            participants: [100, 101]
        )
        harness.callsManager.endCallExpectationClosure = {
            expectation.fulfill()
        }
        harness.callUpdateUseCase.sendCallUpdate(callUpdate)
        
        await fulfillment(of: [expectation], timeout: 0.5)
        XCTAssertEqual(harness.callsManager.removeCall_CalledTimes, 1)
    }
    
    @MainActor
    func testAnswerCall_withSpeakerDisabled_shouldNotCallEnableSpeaker() async throws {
        let harness = Harness()
        harness.callUseCase.answerCallCompletion = .success(CallEntity())
        
        _ = await harness.sut.answerCall(.speakerEnabled(false))
        XCTAssertEqual(harness.audioSessionUseCase.enableLoudSpeaker_calledTimes, 0)
    }
    
    @MainActor
    func testAnswerCall_withSpeakerEnabled_shouldCallEnableSpeaker() async throws {
        let harness = Harness()
        harness.callUseCase.answerCallCompletion = .success(CallEntity())
        
        _ = await harness.sut.answerCall(.speakerEnabled(true))
        XCTAssertEqual(harness.audioSessionUseCase.enableLoudSpeaker_calledTimes, 1)
    }
    
    @MainActor
    func testStartCall_withSpeakerEnabled_shouldCallEnableSpeaker() async throws {
        let harness = Harness()
        harness.callUseCase.callCompletion = .success(CallEntity())
        
        _ = await harness.sut.startCall(.speakerEnabled(true))
        XCTAssertEqual(harness.audioSessionUseCase.enableLoudSpeaker_calledTimes, 1)
    }
    
    @MainActor
    func testStartCall_withSpeakerDisabled_shouldNotCallEnableSpeaker() async throws {
        let harness = Harness()
        harness.callUseCase.callCompletion = .success(CallEntity())
        
        _ = await harness.sut.startCall(.speakerEnabled(false))
        XCTAssertEqual(harness.audioSessionUseCase.enableLoudSpeaker_calledTimes, 0)
    }
    
    @MainActor
    func testStartCall_joiningActiveCall_shouldNotCallStartNoUserJoinedCountdown() async throws {
        let harness = Harness()
        harness.callUseCase.callCompletion = .success(CallEntity())
        
        _ = await harness.sut.startCall(.isJoiningActiveCall(true))
        XCTAssertEqual(harness.meetingNoUserJoinedUseCase.startTimer_calledTimes, 0)
    }
    
    @MainActor
    func testStartCall_notJoiningActiveCall_shouldCallStartNoUserJoinedCountdown() async throws {
        let harness = Harness()
        harness.callUseCase.callCompletion = .success(CallEntity())
        
        _ = await harness.sut.startCall(.isJoiningActiveCall(false))
        XCTAssertEqual(harness.meetingNoUserJoinedUseCase.startTimer_calledTimes, 1)
    }
    
    @MainActor
    func testOutgoingCall_statusChangeToJoining_shouldReportOutgoingCallStartedConnecting() async throws {
        let harness = Harness.withOutgoingCall(in: .testChatRoomEntity)
        
        let callUpdate = CallEntity(
            status: .joining,
            chatId: 123,
            changeType: .status,
            isOwnClientCaller: true
        )
        harness.callUpdateUseCase.sendCallUpdate(callUpdate)
        
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.reportOutgoingCallStartedConnecting_calledTimes, 1)
    }
    
    @MainActor
    func testOutgoingCall_statusChangeToInProgress_shouldReportOutgoingCallConnected() async throws {
        let harness = Harness.withOutgoingCall(in: .testChatRoomEntity)

        let callUpdate = CallEntity(
            status: .inProgress,
            chatId: 123,
            changeType: .status,
            isOwnClientCaller: true
        )
        harness.callUpdateUseCase.sendCallUpdate(callUpdate)
        
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.reportOutgoingCallConnected_calledTimes, 1)
    }
}

extension ChatRoomEntity {
    static var testChatRoomEntity: Self {
        ChatRoomEntity(chatId: 123)
    }
}

extension CallActionSync {
    static func speakerEnabled(_ enabled: Bool) -> Self {
        CallActionSync(chatRoom: .testChatRoomEntity, speakerEnabled: enabled)
    }
    
    static func isJoiningActiveCall(_ activeCall: Bool) -> Self {
        CallActionSync(chatRoom: .testChatRoomEntity, isJoiningActiveCall: activeCall)
    }
}

struct MockCallKitProviderDelegateFactory: CallKitProviderDelegateProviding {
    class MockCXProviderDelegate: NSObject, CallKitProviderDelegateProtocol {
        
        var reportOutgoingCallStartedConnecting_calledTimes = 0
        var reportOutgoingCallConnected_calledTimes = 0
        var updateCallTitle_calledTimes = 0
        var updateCallVideo_calledTimes = 0
        var reportNewIncomingCall_calledTimes = 0
        var reportEndedCall_calledTimes = 0
        
        func reportOutgoingCallStartedConnecting(with uuid: UUID) {
            reportOutgoingCallStartedConnecting_calledTimes += 1
        }
        
        func reportOutgoingCallConnected(with uuid: UUID) {
            reportOutgoingCallConnected_calledTimes += 1
        }

        func updateCallTitle(_ title: String, for callUUID: UUID) {
            updateCallTitle_calledTimes += 1
        }
        
        func updateCallVideo(_ video: Bool, for callUUID: UUID) {
            updateCallVideo_calledTimes += 1
        }
        
        func reportNewIncomingCall(with uuid: UUID, title: String, completion: @escaping (Bool) -> Void) {
            reportNewIncomingCall_calledTimes += 1
            completion(true)
        }
        
        func reportEndedCall(with uuid: UUID, reason: EndCallReason) {
            reportEndedCall_calledTimes += 1
        }
    }
    
    let delegate = MockCXProviderDelegate()
    func build(
        callCoordinator: any CallsCoordinatorProtocol,
        callsManager: any CallsManagerProtocol
    ) -> any CallKitProviderDelegateProtocol {
        delegate
    }
}
