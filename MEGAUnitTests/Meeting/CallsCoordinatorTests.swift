import CallKit
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import XCTest

class MockCXCallUpdate: CXCallUpdate { }

final class CallsCoordinatorTests: XCTestCase {
    
    class Harness {
        let sut: CallsCoordinator
        let chatRoomUseCase: MockChatRoomUseCase
        let callUseCase: MockCallUseCase
        let callUpdateUseCase: MockCallUpdateUseCase
        let audioSessionUseCase: MockAudioSessionUseCase
        let callManager = MockCallManager()
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
                callManager: callManager,
                passcodeManager: MockPasscodeManager(),
                uuidFactory: { .testUUID },
                callUpdateFactory: CXCallUpdateFactory(builder: { MockCXCallUpdate() }),
                callKitProviderDelegateFactory: callKitProviderDelegateFactory
            )
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
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.incomingCalls, [.init(uuid: .testUUID, chatRoom: .testChatRoomEntity)])
    }
    
    @MainActor
    func testReportIncomingCall_ExistingCall_DoesNotReportAgainToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.callManager.addIncomingCall(withUUID: .testUUID, chatRoom: .testChatRoomEntity) // simulating existing call
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.addIncomingCall_CalledTimes, 1)
    }
    
    @MainActor
    func testReportIncomingCall_ExistingCall_ProviderDelegateCalled_CompletionTriggered() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.callManager.addIncomingCall(withUUID: .testUUID, chatRoom: .testChatRoomEntity) // simulating existing call
        var completionCalled = false
        harness.sut.reportIncomingCall(in: 123, completion: { completionCalled = true })
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.mockProvider.reportNewIncomingCalls, [.testUUID])
        XCTAssertTrue(completionCalled)
    }
    
    @MainActor
    func testReportIncomingCall_NewCall_ProviderDelegateCalled_CompletionTriggered() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        var completionCalled = false
        harness.sut.reportIncomingCall(in: 123, completion: { completionCalled = true })
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.mockProvider.reportNewIncomingCalls, [.testUUID])
        XCTAssertTrue(completionCalled)
    }
    
    @MainActor
    func testReportIncomingCall_CallExistsInChatUserIsParticipating_DoesNotReportToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .inProgress))
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.incomingCalls, [])
    }
    
    @MainActor
    func testReportIncomingCall_CallExistsInChatUserIsNotParticipating_ReportToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .userNoPresent))
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.incomingCalls, [.init(uuid: .testUUID, chatRoom: .testChatRoomEntity)])
    }
    
    @MainActor
    func testReportIncomingCall_UserHasAlreadyAnsweredInOtherDevice_ShouldReportEndCall() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .userNoPresent, participants: [100, 101]))
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.removeCall_CalledTimes, 1)
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
        
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.mockProvider.reportNewIncomingCalls, [.testUUID])
        
        let callUpdate = CallEntity(
            status: .userNoPresent,
            changeType: .ringingStatus,
            isRinging: false,
            participants: [100, 101]
        )
        harness.callManager.endCallExpectationClosure = {
            expectation.fulfill()
        }
        harness.callUpdateUseCase.sendCallUpdate(callUpdate)
        
        await fulfillment(of: [expectation], timeout: 0.5)
        XCTAssertEqual(harness.callManager.removeCall_CalledTimes, 1)
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
        let provider: CXProvider = MockCXProvider(configuration: CXProviderConfiguration())
        
        var mockProvider: MockCXProvider {
            provider as! MockCXProvider
        }
    }
    
    let delegate = MockCXProviderDelegate()
    func build(
        callCoordinator: any CallsCoordinatorProtocol,
        callManager: any CallManagerProtocol
    ) -> any CallKitProviderDelegateProtocol {
        delegate
    }
}
