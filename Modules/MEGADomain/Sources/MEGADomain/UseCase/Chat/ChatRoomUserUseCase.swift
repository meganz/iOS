import Foundation

public protocol ChatRoomUserUseCaseProtocol: Sendable {
    func userFullNames(for chatRoom: ChatRoomEntity) async throws -> [String]
    func userDisplayName(forPeerId peerId: HandleEntity, in chatRoom: ChatRoomEntity) async throws -> String
    func userDisplayNames(forPeerIds peerIds: [HandleEntity], in chatRoom: ChatRoomEntity) async throws -> [String]
    func userNickNames(for chatRoom: ChatRoomEntity) async -> [HandleEntity: String]
    func userEmails(for chatRoom: ChatRoomEntity) async -> [HandleEntity: String]
    func contactEmail(forUserHandle userHandle: HandleEntity) -> String?
    func userEmail(forUserHandle userHandle: HandleEntity) async throws -> String
    func chatRoomUsersDescription(for chatRoom: ChatRoomEntity) async throws -> String
}

public struct ChatRoomUserUseCase<T: ChatRoomUserRepositoryProtocol, U: UserStoreRepositoryProtocol>: ChatRoomUserUseCaseProtocol {
    private var chatRoomRepo: T
    private let userStoreRepo: U
    
    public init(chatRoomRepo: T, userStoreRepo: U) {
        self.chatRoomRepo = chatRoomRepo
        self.userStoreRepo = userStoreRepo
    }
    
    public func userFullNames(for chatRoom: ChatRoomEntity) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for peerId in chatRoom.peers.map(\.handle) {
                group.addTask { try await chatRoomRepo.userFullName(forPeerId: peerId, chatRoom: chatRoom) }
            }
            
            return try await group.reduce(into: [String]()) { result, name in
                result.append(name)
            }
        }
    }
    
    public func userNickNames(for chatRoom: ChatRoomEntity) async -> [HandleEntity: String] {
        await withTaskGroup(
            of: [HandleEntity: String]?.self,
            returning: [HandleEntity: String].self
        ) { group in
            for peerId in chatRoom.peers.map(\.handle) {
                group.addTask {
                    if let displayName = await userStoreRepo.displayName(forUserHandle: peerId) {
                        return [peerId: displayName]
                    } else {
                        return nil
                    }
                }
            }
            
            return await group.reduce(into: [HandleEntity: String]()){ result, handleEntityNamePair in
                if let handleEntityNamePair {
                    for (key, value) in handleEntityNamePair {
                        result[key] = value
                    }
                }
            }
        }
    }
    
    public func userEmails(for chatRoom: ChatRoomEntity) async -> [HandleEntity: String] {
        await withTaskGroup(
            of: [HandleEntity: String]?.self,
            returning: [HandleEntity: String].self
        ) { group in
            for peerId in chatRoom.peers.map(\.handle) {
                group.addTask {
                    if let displayName = chatRoomRepo.contactEmail(forUserHandle: peerId) {
                        return [peerId: displayName]
                    } else {
                        return nil
                    }
                }
            }
            
            return await group.reduce(into: [HandleEntity: String]()){ result, handleEntityEmailPair in
                if let handleEntityEmailPair {
                    for (key, value) in handleEntityEmailPair {
                        result[key] = value
                    }
                }
            }
        }
    }
    
    public func userDisplayNames(forPeerIds peerIds: [HandleEntity], in chatRoom: ChatRoomEntity) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for peerId in peerIds {
                group.addTask {
                    if let nickName = await userStoreRepo.displayName(forUserHandle: peerId) {
                        return nickName
                    }
                    
                    return try await chatRoomRepo.userFullName(forPeerId: peerId, chatRoom: chatRoom)
                }
            }
            
            return try await group.reduce(into: [String]()) { result, name in
                result.append(name)
            }
        }
    }
    
    public func userDisplayName(forPeerId peerId: HandleEntity, in chatRoom: ChatRoomEntity) async throws -> String {
        if let name = await userStoreRepo.displayName(forUserHandle: peerId) {
            return name
        } else {
            return try await chatRoomRepo.userFullName(forPeerId: peerId, chatRoom: chatRoom)
        }
    }
    
    public func contactEmail(forUserHandle userHandle: HandleEntity) -> String? {
        chatRoomRepo.contactEmail(forUserHandle: userHandle)
    }
    
    public func userEmail(forUserHandle userHandle: HandleEntity) async throws -> String {
        try await chatRoomRepo.userEmail(forUserHandle: userHandle)
    }
    
    public func chatRoomUsersDescription(for chatRoom: ChatRoomEntity) async throws -> String {
        async let fullNamesTask = userFullNames(for: chatRoom).joined(separator: " ")
        async let userNickNamesTask = userNickNames(for: chatRoom).values.joined(separator: " ")
        async let userEmailsTask = userEmails(for: chatRoom).values.joined(separator: " ")
        
        let (fullNames, userNickNames, userEmails) = try await (fullNamesTask, userNickNamesTask, userEmailsTask)
        
        if let title = chatRoom.title {
            return title + " " + fullNames + " " + userNickNames + " " + userEmails
        } else {
            return fullNames + " " + userNickNames + " " + userEmails
        }
    }
}
