import CallKit
import CombineSchedulers
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
        let callManager = MockCallManager()
        let callKitProviderDelegateFactory = MockCallKitProviderDelegateFactory()
        init(
            scheduler: AnySchedulerOf<DispatchQueue> = .main,
            chatRoomEntity: ChatRoomEntity? = nil,
            call: CallEntity? = nil
        ) {
            chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
            callUseCase = MockCallUseCase(call: call)
            sut = CallsCoordinator(
                scheduler: scheduler,
                callUseCase: callUseCase,
                chatRoomUseCase: chatRoomUseCase,
                chatUseCase: MockChatUseCase(myUserHandle: 101),
                sessionUpdateUseCase: MockSessionUpdateUseCase(),
                noUserJoinedUseCase: MockMeetingNoUserJoinedUseCase(),
                captureDeviceUseCase: MockCaptureDeviceUseCase(),
                callManager: callManager,
                passcodeManager: MockPasscodeManager(),
                uuidFactory: { .testUUID },
                callUpdateFactory: CXCallUpdateFactory(builder: { MockCXCallUpdate() }),
                callKitProviderDelegateFactory: callKitProviderDelegateFactory
            )
        }
    }
    
    func testReportIncomingCall_UnknownCall_DoesNothing() {
        let harness = Harness()
        harness.sut.reportIncomingCall(in: 123, completion: {})
    }
    
    func testReportIncomingCall_NewCall_ReportsToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.incomingCalls, [.init(uuid: .testUUID, chatRoom: .testChatRoomEntity)])
    }
    
    func testReportIncomingCall_ExistingCall_DoesNotReportAgainToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.callManager.addIncomingCall(withUUID: .testUUID, chatRoom: .testChatRoomEntity) // simulating existing call
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.addIncomingCall_CalledTimes, 1)
    }
    
    func testReportIncomingCall_ExistingCall_ProviderDelegateCalled_CompletionTriggered() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.callManager.addIncomingCall(withUUID: .testUUID, chatRoom: .testChatRoomEntity) // simulating existing call
        var completionCalled = false
        harness.sut.reportIncomingCall(in: 123, completion: { completionCalled = true })
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.mockProvider.reportNewIncomingCalls, [.testUUID])
        XCTAssertTrue(completionCalled)
    }
    
    func testReportIncomingCall_NewCall_ProviderDelegateCalled_CompletionTriggered() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        var completionCalled = false
        harness.sut.reportIncomingCall(in: 123, completion: { completionCalled = true })
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.mockProvider.reportNewIncomingCalls, [.testUUID])
        XCTAssertTrue(completionCalled)
    }
    
    func testReportIncomingCall_CallExistsInChatUserIsParticipating_DoesNotReportToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .inProgress))
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.incomingCalls, [])
    }
    
    func testReportIncomingCall_CallExistsInChatUserIsNotParticipating_ReportToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .userNoPresent))
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.incomingCalls, [.init(uuid: .testUUID, chatRoom: .testChatRoomEntity)])
    }
    
    func testReportIncomingCall_UserHasAlreadyAnsweredInOtherDevice_ShouldReportEndCall() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity, call: CallEntity(status: .userNoPresent, participants: [100, 101]))
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.removeCall_CalledTimes, 1)
    }
    
    func testOnChatCallUpdate_StopRingingAndUserNotParticipant_ShouldReportEndCall() {
        let scheduler = DispatchQueue.test
        let harness = Harness(
            scheduler: scheduler.eraseToAnyScheduler(),
            chatRoomEntity: .testChatRoomEntity,
            call: CallEntity(status: .userNoPresent, participants: [100])
        )
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.mockProvider.reportNewIncomingCalls, [.testUUID])

        harness.callUseCase.callUpdateSubject.send(CallEntity(status: .userNoPresent, changeType: .ringingStatus, isRinging: false, participants: [100, 101]))
        scheduler.advance(by: .milliseconds(600))
        XCTAssertEqual(harness.callManager.removeCall_CalledTimes, 1)
    }
}

extension ChatRoomEntity {
    static var testChatRoomEntity: Self {
        ChatRoomEntity(chatId: 123)
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
