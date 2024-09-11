import Foundation
import MEGAChatSdk
import MEGADomain
import MEGASwift

public struct ManageChatHistoryRepository: ManageChatHistoryRepositoryProtocol {
    private let chatSdk: MEGAChatSdk
    
    public init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func chatRetentionTime(for chatId: ChatIdEntity) async throws -> UInt {
        if let chatRoom = chatSdk.chatRoom(forChatId: chatId) {
            return chatRoom.retentionTime
        } else {
            throw ManageChatHistoryErrorEntity.generic
        }
    }
    
    public func setChatRetentionTime(for chatId: ChatIdEntity, period: UInt) async throws -> UInt {
        try await withAsyncThrowingValue { completion in
            chatSdk.setChatRetentionTime(chatId, period: period, delegate: ChatRequestDelegate { result in
                switch result {
                case .success(let request):
                    let requestPeriod = UInt(truncatingIfNeeded: request.number)
                    completion(.success(requestPeriod))
                case .failure(let error):
                    completion(.failure(error.toManageChatHistoryErrorEntity()))
                }
            })
        }
    }
    
    public func clearChatHistory(for chatId: ChatIdEntity) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.clearChatHistory(chatId, delegate: ChatRequestDelegate { request in
                switch request {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error.toManageChatHistoryErrorEntity()))
                }
            })
        }
    }
}

private extension MEGAChatError {
    func toManageChatHistoryErrorEntity() -> ManageChatHistoryErrorEntity {
        switch type {
        case .MEGAChatErrorTypeArgs:
            return .chatIdInvalid
        case .MEGAChatErrorTypeNoEnt:
            return .chatIdDoesNotExist
        case .MEGAChatErrorTypeAccess:
            return .notEnoughPrivileges
        default:
            return .generic
        }
    }
}
