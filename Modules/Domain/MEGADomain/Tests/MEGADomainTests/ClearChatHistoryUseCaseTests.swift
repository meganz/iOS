import MEGADomain
import MEGADomainMock
import XCTest

final class ClearChatHistoryUseCaseTests: XCTestCase {
    func test_clearChatHistory_success() async {
        let repo = MockManageChatHistoryRepository(clearChatHistory: .success)
        let sut = ClearChatHistoryUseCase(repository: repo)
        do {
            try await sut.clearChatHistory(for: 123)
            XCTAssertTrue(true)
        } catch {
            XCTFail("errors are not expected!")
        }
    }
    
    func test_clearChatHistory_errorGeneric() async {
        let mockError: ManageChatHistoryErrorEntity = .generic
        let repo = MockManageChatHistoryRepository()
        let sut = ClearChatHistoryUseCase(repository: repo)
        do {
            try await sut.clearChatHistory(for: 123)
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? ManageChatHistoryErrorEntity)
        }
    }
    
    func test_clearChatHistory_error_chatIdInvalid() async {
        let mockError: ManageChatHistoryErrorEntity = .chatIdInvalid
        let repo = MockManageChatHistoryRepository(clearChatHistory: .failure(.chatIdInvalid))
        let sut = ClearChatHistoryUseCase(repository: repo)
        
        do {
            try await sut.clearChatHistory(for: 123)
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? ManageChatHistoryErrorEntity)
        }
    }
    
    func test_clearChatHistory_error_chatIdDoesNotExist() async {
        let mockError: ManageChatHistoryErrorEntity = .chatIdDoesNotExist
        let repo = MockManageChatHistoryRepository(clearChatHistory: .failure(.chatIdDoesNotExist))
        let sut = ClearChatHistoryUseCase(repository: repo)
        do {
            try await sut.clearChatHistory(for: 123)
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? ManageChatHistoryErrorEntity)
        }
    }
    
    func test_clearChatHistory_error_notEnoughPrivileges() async {
        let mockError: ManageChatHistoryErrorEntity = .notEnoughPrivileges
        let repo = MockManageChatHistoryRepository(clearChatHistory: .failure(.notEnoughPrivileges))
        let sut = ClearChatHistoryUseCase(repository: repo)
        do {
            try await sut.clearChatHistory(for: 123)
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? ManageChatHistoryErrorEntity)
        }
    }
}
