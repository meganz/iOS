import Foundation
import MEGADomain

public struct MockChatRoomUserUseCase: ChatRoomUserUseCaseProtocol {
    private let userFullNamesResult: Result<[String], Error>
    private let userDisplayNameForPeerResult: Result<String, Error>
    private let userDisplayNamesForPeersResult: Result<[(HandleEntity, String)], any Error>
    private let userNickNames: [HandleEntity: String]
    private let userEmails: [HandleEntity: String]
    private let contactEmail: String?
    private let chatRoomUsersDescriptionResult: Result<String, Error>
    private let userEmail: Result<String, Error>

    public init(
        userFullNamesResult: Result<[String], Error> = .failure(GenericErrorEntity()),
        userDisplayNameForPeerResult: Result<String, Error> = .failure(GenericErrorEntity()),
        userDisplayNamesForPeersResult: Result<[(HandleEntity, String)], Error> = .failure(GenericErrorEntity()),
        userNickNames: [HandleEntity: String] = [:],
        userEmails: [HandleEntity: String] = [:],
        contactEmail: String? = nil,
        chatRoomUsersDescriptionResult: Result<String, Error> = .failure(GenericErrorEntity()),
        userEmail: Result<String, Error> = .failure(GenericErrorEntity())
    ) {
        self.userFullNamesResult = userFullNamesResult
        self.userDisplayNameForPeerResult = userDisplayNameForPeerResult
        self.userDisplayNamesForPeersResult = userDisplayNamesForPeersResult
        self.userNickNames = userNickNames
        self.userEmails = userEmails
        self.contactEmail = contactEmail
        self.chatRoomUsersDescriptionResult = chatRoomUsersDescriptionResult
        self.userEmail = userEmail
    }
    
    public func userFullNames(for chatRoom: ChatRoomEntity) async throws -> [String] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: userFullNamesResult)
        }
    }
    
    public func userDisplayName(forPeerId peerId: HandleEntity, in chatRoom: ChatRoomEntity) async throws -> String {
        try await withCheckedThrowingContinuation {
            $0.resume(with: userDisplayNameForPeerResult)
        }
    }
    
    public func userDisplayNames(forPeerIds peerIds: [HandleEntity], in chatRoom: ChatRoomEntity) async throws -> [String] {
        switch userDisplayNamesForPeersResult {
        case .success(let handleNamePairArray):
            return peerIds.compactMap { handle in
                return handleNamePairArray.first(where: { $0.0 == handle })?.1
            }
        case .failure(let error):
            throw error
        }
    }
    
    public func userNickNames(for chatRoom: ChatRoomEntity) async -> [HandleEntity: String] {
        userNickNames
    }
    
    public func userEmails(for chatRoom: ChatRoomEntity) async -> [HandleEntity: String] {
        userEmails
    }
    
    public func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        contactEmail
    }
    
    public func userEmail(forUserHandle userHandle: MEGADomain.HandleEntity) async throws -> String {
        try await withCheckedThrowingContinuation {
            $0.resume(with: userEmail)
        }
    }
    
    public func chatRoomUsersDescription(for chatRoom: ChatRoomEntity) async throws -> String {
        try await withCheckedThrowingContinuation {
            $0.resume(with: chatRoomUsersDescriptionResult)
        }
    }
}
