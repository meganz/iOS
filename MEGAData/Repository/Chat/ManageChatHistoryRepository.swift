
import Foundation
import MEGADomain

typealias ChatId = UInt64

struct ManageChatHistoryRepository: ManageChatHistoryRepositoryProtocol {
    private let chatSdk: MEGAChatSdk
    
    init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    func chatRetentionTime(for chatId: ChatId, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        if let chatRoom = chatSdk.chatRoom(forChatId: chatId) {
            completion(.success(chatRoom.retentionTime))
        } else {
            completion(.failure(.generic))
        }
    }
    
    func setChatRetentionTime(for chatId: ChatId, period: UInt, completion: @escaping (Result<UInt, ManageChatHistoryErrorEntity>) -> Void) {
        let delegate = MEGAChatGenericRequestDelegate { request, error in
            if error.type == .MEGAChatErrorTypeOk {
                let requestPeriod = UInt(truncatingIfNeeded: request.number)
                completion(.success(requestPeriod))
                return
            }
            
            let chatRetentionTimeError: ManageChatHistoryErrorEntity
            switch error.type {
            case .MEGAChatErrorTypeArgs:
                chatRetentionTimeError = .chatIdInvalid
                
            case .MEGAChatErrorTypeNoEnt:
                chatRetentionTimeError = .chatIdDoesNotExist
                
            case .MEGAChatErrorTypeAccess:
                chatRetentionTimeError = .notEnoughPrivileges
                
            default:
                chatRetentionTimeError = .generic
            }
            
            completion(.failure(chatRetentionTimeError))
        }
        
        chatSdk.setChatRetentionTime(chatId, period: period, delegate: delegate)
    }
    
    func clearChatHistory(for chatId: ChatId, completion: @escaping (Result<Void, ManageChatHistoryErrorEntity>) -> Void) {
        chatSdk.clearChatHistory(chatId, delegate: MEGAChatGenericRequestDelegate { request, error in
            let clearChatHistoryError: ManageChatHistoryErrorEntity
            switch error.type {
            case .MEGAChatErrorTypeOk:
                completion(.success(()))
                return
            
            case .MEGAChatErrorTypeArgs:
                clearChatHistoryError = .chatIdInvalid
                
            case .MEGAChatErrorTypeNoEnt:
                clearChatHistoryError = .chatIdDoesNotExist
                
            case .MEGAChatErrorTypeAccess:
                clearChatHistoryError = .notEnoughPrivileges
                
            default:
                clearChatHistoryError = .generic
            }
            
            completion(.failure(clearChatHistoryError))
        })
    }
}
