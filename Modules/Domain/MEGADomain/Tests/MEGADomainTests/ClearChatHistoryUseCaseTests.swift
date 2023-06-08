
import XCTest
import MEGADomain
import MEGADomainMock

final class ClearChatHistoryUseCaseTests: XCTestCase {
    func test_clearChatHistory_success() {
        let repo = MockManageChatHistoryRepository(clearChatHistory: .success)
        let sut = ClearChatHistoryUseCase(repository: repo)
        sut.clearChatHistory(for: 123) { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func test_clearChatHistory_errorGeneric() {
        let mockError: ManageChatHistoryErrorEntity = .generic
        let repo = MockManageChatHistoryRepository()
        let sut = ClearChatHistoryUseCase(repository: repo)
        sut.clearChatHistory(for: 123) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func test_clearChatHistory_error_chatIdInvalid () {
        let mockError: ManageChatHistoryErrorEntity = .chatIdInvalid
        let repo = MockManageChatHistoryRepository(clearChatHistory: .failure(.chatIdInvalid))
        let sut = ClearChatHistoryUseCase(repository: repo)
        sut.clearChatHistory(for: 123) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func test_clearChatHistory_error_chatIdDoesNotExist () {
        let mockError: ManageChatHistoryErrorEntity = .chatIdDoesNotExist
        let repo = MockManageChatHistoryRepository(clearChatHistory: .failure(.chatIdDoesNotExist))
        let sut = ClearChatHistoryUseCase(repository: repo)
        sut.clearChatHistory(for: 123) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func test_clearChatHistory_error_notEnoughPrivileges () {
        let mockError: ManageChatHistoryErrorEntity = .notEnoughPrivileges
        let repo = MockManageChatHistoryRepository(clearChatHistory: .failure(.notEnoughPrivileges))
        let sut = ClearChatHistoryUseCase(repository: repo)
        sut.clearChatHistory(for: 123) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
}
