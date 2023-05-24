import Foundation
import MEGADomain

public struct MockChatRoomUserRepository: ChatRoomUserRepositoryProtocol {
    public static var newRepo: MockChatRoomUserRepository {
        MockChatRoomUserRepository()
    }
    
    private let userFullNameResult: Result<String, Error>
    private let contactEmail: String?
    private let userEmailResult: Result<String, Error>

    public init(userFullNameResult: Result<String, Error> = .failure(GenericErrorEntity()),
                contactEmail: String? = nil,
                userEmailResult: Result<String, Error> = .failure(GenericErrorEntity())) {
        self.userFullNameResult = userFullNameResult
        self.contactEmail = contactEmail
        self.userEmailResult = userEmailResult
    }
    
    public func userFullName(forPeerId peerId: HandleEntity, chatRoom: ChatRoomEntity) async throws -> String {
        try await withCheckedThrowingContinuation {
            $0.resume(with: userFullNameResult)
        }
    }
    
    public func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        contactEmail
    }
    
    public func userEmail(forUserHandle userHandle: HandleEntity) async throws -> String {
        try await withCheckedThrowingContinuation {
            $0.resume(with: userEmailResult)
        }
    }
}
