@testable import MEGA
import MEGADomainMock
import PushKit
import XCTest

final class VoIPPushDelegateTests: XCTestCase {
    class Harness {
        let sut: VoIPPushDelegate
        let voIpTokenUseCase = MockVoIPTokenUseCase()
        let callsCoordinator = MockCallsCoordinator()
        
        init(
            handle: MEGAHandle? = nil
        ) {
            sut = VoIPPushDelegate(
                callCoordinator: callsCoordinator,
                voIpTokenUseCase: voIpTokenUseCase,
                megaHandleUseCase: MockMEGAHandleUseCase(userHandle: handle),
                logger: { _ in }
            )
        }
        
        func updateCredentialsDidRegisterToken(_ credentials: MockPushCredentials, type: PKPushType) -> Bool {
            sut.pushRegistry(PKPushRegistry(queue: nil), didUpdate: credentials, for: type)
            return voIpTokenUseCase.registerVoIPDeviceToken_CalledTimes > 0
        }
        
        enum TestTokenType {
            case empty
            case nonEmpty
            
            var data: Data {
                switch self {
                case .empty:
                    Data()
                case .nonEmpty:
                    generateRandomData(length: 32)
                }
            }
            
            private func generateRandomData(length: Int) -> Data {
                var data = Data(count: length)
                data.withUnsafeMutableBytes { mutableBytes in
                    guard let bytes = mutableBytes.baseAddress else { return }
                    _ = SecRandomCopyBytes(kSecRandomDefault, length, bytes)
                }
                return data
            }
        }
        
        func updateCredentialsUsingToken(tokenType: TestTokenType, type: PKPushType) -> Bool {
            let credentials = MockPushCredentials(mockToken: tokenType.data)
            sut.pushRegistry(PKPushRegistry(queue: nil), didUpdate: credentials, for: type)
            return voIpTokenUseCase.registerVoIPDeviceToken_CalledTimes > 0
        }
        
        @MainActor
        func receiveIncomingPushDidReportIncomingCall(_ payload: MockPushPayload) -> Bool {
            sut.pushRegistry(PKPushRegistry(queue: nil), didReceiveIncomingPushWith: payload, for: .voIP, completion: { })
            return callsCoordinator.reportIncomingCall_CalledTimes > 0
        }
    }
    
    class MockPushPayload: PKPushPayload {
        var mockDictionary: [AnyHashable: Any]

        init(mockDictionary: [AnyHashable: Any]) {
            self.mockDictionary = mockDictionary
            super.init()
        }
        
        override var dictionaryPayload: [AnyHashable: Any] {
            return mockDictionary
        }
    }

    class MockPushCredentials: PKPushCredentials {
        var mockToken: Data

        init(mockToken: Data) {
            self.mockToken = mockToken
            super.init()
        }
        
        override var token: Data {
            return mockToken
        }
    }
    
    func test_registryDidUpdateCredentialsNotVoIPType_shouldNotRegisterVoIPToken() {
        XCTAssertFalse(
            Harness().updateCredentialsUsingToken(tokenType: .empty, type: .fileProvider)
        )
    }
    
    func test_registryDidUpdateCredentialsVoIPTypeEmptyToken_shouldNotRegisterVoIPToken() {
        XCTAssertFalse(
            Harness().updateCredentialsUsingToken(tokenType: .empty, type: .voIP)
        )
    }
    
    func test_registryDidUpdateCredentialsVoIPTypeNoEmptyToken_shouldRegisterVoIPToken() {
        XCTAssertTrue(
            Harness().updateCredentialsUsingToken(tokenType: .nonEmpty, type: .voIP)
        )
    }
    
    @MainActor
    func test_didReceiveIncomingPushWithPayload_isMegaCallAndHasChatId_shouldReportIncomingCall() {
        let expectation = self.expectation(description: "didReportIncomingCall")
        let harness = Harness(handle: 1234567890)
        let payload = MockPushPayload(
            mockDictionary: [
                "megatype": 4,
                "megadata": ["chatid": "chatIdB664Handle"]
            ]
        )
        
        harness.callsCoordinator.reportIncomingCallExpectationClosure = {
            expectation.fulfill()
        }
        _ = harness.receiveIncomingPushDidReportIncomingCall(payload)
        wait(for: [expectation], timeout: 0.5)
        XCTAssertTrue(harness.callsCoordinator.reportIncomingCall_CalledTimes > 0)
    }
    
    @MainActor
    func test_didReceiveIncomingPushWithPayload_isNotMegaCall_shouldNotReportIncomingCall() {
        let payload = MockPushPayload(
            mockDictionary: [
                "megatype": 1,
                "megadata": ["chatid": "chatIdB664Handle"]
            ]
        )
        XCTAssertFalse(
            Harness(handle: 1234567890)
                .receiveIncomingPushDidReportIncomingCall(payload)
        )
    }
    
    @MainActor
    func test_didReceiveIncomingPushWithPayload_isMegaCallNoChatId_shouldNotReportIncomingCall() {
        let payload = MockPushPayload(
            mockDictionary: [
                "megatype": 4,
                "megadata": ""
            ]
        )
        XCTAssertFalse(
            Harness(handle: 1234567890)
                .receiveIncomingPushDidReportIncomingCall(payload)
        )
    }
}
