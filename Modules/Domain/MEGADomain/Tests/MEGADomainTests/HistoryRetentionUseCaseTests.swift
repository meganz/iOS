import MEGADomain
import MEGADomainMock
import XCTest

final class HistoryRetentionUseCaseTests: XCTestCase {
    
    func test_chatRetentionTime_success() async {
        let mockValue: UInt = 60
        let repo = MockManageChatHistoryRepository(chatRetentionTime: .success(mockValue))
        let sut = HistoryRetentionUseCase(repository: repo)
        do {
            let value = try await sut.chatRetentionTime(for: 123)
            XCTAssertEqual(mockValue, value)
        } catch {
            XCTFail("errors are not expected!")
        }
    }
    
    func test_chatRetentionTime_error_generic() async {
        let mockError: ManageChatHistoryErrorEntity = .generic
        let repo = MockManageChatHistoryRepository()
        let sut = HistoryRetentionUseCase(repository: repo)
        do {
            _ = try await sut.chatRetentionTime(for: 123)
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? ManageChatHistoryErrorEntity)
        }
    }
    
    func test_setChatRetentionTime_success() async {
        let mockValue: UInt = 60
        let repo = MockManageChatHistoryRepository(setChatRetentionTime: .success(mockValue))
        let sut = HistoryRetentionUseCase(repository: repo)
        do {
            let value = try await sut.setChatRetentionTime(for: 123, period: 6)
            XCTAssertEqual(mockValue, value)
        } catch {
            XCTFail("errors are not expected!")
        }
    }
    
    func test_setChatRetentionTime_error_generic() async {
        let mockError: ManageChatHistoryErrorEntity = .generic
        let repo = MockManageChatHistoryRepository()
        let sut = HistoryRetentionUseCase(repository: repo)
        do {
            _ = try await sut.setChatRetentionTime(for: 123, period: 6)
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? ManageChatHistoryErrorEntity)
        }
    }
    
    func test_setChatRetentionTime_error_chatIdInvalid() async {
        let mockError: ManageChatHistoryErrorEntity = .chatIdInvalid
        let repo = MockManageChatHistoryRepository(setChatRetentionTime: .failure(.chatIdInvalid))
        let sut = HistoryRetentionUseCase(repository: repo)
        do {
            _ = try await sut.setChatRetentionTime(for: 123, period: 6)
        } catch {
            XCTAssertEqual(mockError, error as? ManageChatHistoryErrorEntity)
        }
    }
    
    func test_setChatRetentionTime_error_notEnoughPrivileges() async {
        let mockError: ManageChatHistoryErrorEntity = .notEnoughPrivileges
        let repo = MockManageChatHistoryRepository(setChatRetentionTime: .failure(.notEnoughPrivileges))
        let sut = HistoryRetentionUseCase(repository: repo)
        do {
            _ = try await sut.setChatRetentionTime(for: 123, period: 6)
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? ManageChatHistoryErrorEntity)
        }
    }
}
