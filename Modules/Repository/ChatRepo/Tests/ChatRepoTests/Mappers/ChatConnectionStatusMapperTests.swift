import ChatRepo
import MEGAChatSdk
import MEGADomain
import XCTest

class ChatConnectionStatusMapperTests: XCTestCase {
    func testChatConnectionStatus_forDifferentChatConnectionType_shouldReturnCorrectMapping() {
        let types: [MEGAChatConnection] = [.offline, .inProgress, .logging, .online]
        for type in types {
            let sut = type.toChatConnectionStatus()
            switch type {
            case .offline: 
                XCTAssertEqual(sut, .offline)
            case .inProgress: 
                XCTAssertEqual(sut, .inProgress)
            case .logging: 
                XCTAssertEqual(sut, .logging)
            case .online: 
                XCTAssertEqual(sut, .online)
            default: 
                break
            }
        }
    }
}
