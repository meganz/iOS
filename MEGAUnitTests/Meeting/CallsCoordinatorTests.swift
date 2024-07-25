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
        let callManager = MockCallManager()
        let callKitProviderDelegateFactory = MockCallKitProviderDelegateFactory()
        init(
            chatRoomEntity: ChatRoomEntity? = nil,
            call: CallEntity? = nil
        ) {
            chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
            
            sut = CallsCoordinator(
                callUseCase: MockCallUseCase(call: call),
                chatRoomUseCase: chatRoomUseCase,
                chatUseCase: MockChatUseCase(),
                callSessionUseCase: MockCallSessionUseCase(),
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
        harness.callManager.callUUID = nil // simulating new incoming call
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.incomingCalls, [.init(uuid: .testUUID, chatRoom: .testChatRoomEntity)])
    }
    
    func testReportIncomingCall_ExistingCall_DoesNotReportToCallManager() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.callManager.callUUID = .testUUID // simulating existing call
        harness.sut.reportIncomingCall(in: 123, completion: {})
        XCTAssertEqual(harness.callManager.incomingCalls, [])
    }
    
    func testReportIncomingCall_ExistingCall_ProviderDelegateCalled_CompletionTriggered() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.callManager.callUUID = .testUUID // simulating existing call
        var completionCalled = false
        harness.sut.reportIncomingCall(in: 123, completion: { completionCalled = true })
        XCTAssertEqual(harness.callKitProviderDelegateFactory.delegate.mockProvider.reportNewIncomingCalls, [.testUUID])
        XCTAssertTrue(completionCalled)
    }
    
    func testReportIncomingCall_NewCall_ProviderDelegateCalled_CompletionTriggered() {
        let harness = Harness(chatRoomEntity: .testChatRoomEntity)
        harness.callManager.callUUID = nil // simulating new incoming call
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
