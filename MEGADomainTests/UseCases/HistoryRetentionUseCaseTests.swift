import XCTest
@testable import MEGA

final class HistoryRetentionUseCaseTests: XCTestCase {
    
    func test_chatRetentionTime_success() {
        let mockValue: UInt = 60
        let repo = MockManageChatHistoryRepository(chatRetentionTime: .success(mockValue))
        let sut = HistoryRetentionUseCase(repository: repo)
        sut.chatRetentionTime(for: 123) { result in
            switch result {
            case .success(let value):
                XCTAssertEqual(mockValue, value)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func test_chatRetentionTime_error_generic() {
        let mockError: ManageChatHistoryErrorEntity = .generic
        let repo = MockManageChatHistoryRepository()
        let sut = HistoryRetentionUseCase(repository: repo)
        sut.chatRetentionTime(for: 123) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func test_setChatRetentionTime_success() {
        let mockValue: UInt = 60
        let repo = MockManageChatHistoryRepository(setChatRetentionTime: .success(mockValue))
        let sut = HistoryRetentionUseCase(repository: repo)
        sut.setChatRetentionTime(for: 123, period: 6) { result in
            switch result {
            case .success(let value):
                XCTAssertEqual(mockValue, value)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func test_setChatRetentionTime_error_generic() {
        let mockError: ManageChatHistoryErrorEntity = .generic
        let repo = MockManageChatHistoryRepository()
        let sut = HistoryRetentionUseCase(repository: repo)
        sut.setChatRetentionTime(for: 123, period: 6) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    
    func test_setChatRetentionTime_error_chatIdInvalid() {
        let mockError: ManageChatHistoryErrorEntity = .chatIdInvalid
        let repo = MockManageChatHistoryRepository(setChatRetentionTime:.failure(.chatIdInvalid))
        let sut = HistoryRetentionUseCase(repository: repo)
        sut.setChatRetentionTime(for: 123, period: 6) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    
    func test_setChatRetentionTime_error_notEnoughPrivileges() {
        let mockError: ManageChatHistoryErrorEntity = .notEnoughPrivileges
        let repo = MockManageChatHistoryRepository(setChatRetentionTime:.failure(.notEnoughPrivileges))
        let sut = HistoryRetentionUseCase(repository: repo)
        sut.setChatRetentionTime(for: 123, period: 6) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
}
