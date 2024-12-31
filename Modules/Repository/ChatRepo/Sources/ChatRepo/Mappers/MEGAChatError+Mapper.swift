import MEGAChatSdk
import MEGADomain

extension MEGAChatError: @retroactive Error, @unchecked Sendable{
    func toAllowNonHostToAddParticipantsErrorEntity() -> AllowNonHostToAddParticipantsErrorEntity {
        switch type {
        case .MEGAChatErrorTypeNoEnt:
            return .chatRoomDoesNoExists
        case .MEGAChatErrorTypeArgs:
            return .oneToOneChatRoom
        case .MEGAChatErrorTypeAccess:
            return .access
        case .MegaChatErrorTypeExist:
            return .alreadyExists
        default:
            return .generic
        }
    }

    func toChatLinkErrorEntity() -> ChatLinkErrorEntity {
        switch type {
        case .MEGAChatErrorTypeNoEnt:
            return .resourceNotFound
        default:
            return .generic
        }
    }

    func toWaitingRoomErrorEntity() -> WaitingRoomErrorEntity {
        switch type {
        case .MEGAChatErrorTypeArgs:
            return .oneToOneChatRoom
        case .MEGAChatErrorTypeNoEnt:
            return .chatRoomDoesNoExists
        case .MEGAChatErrorTypeAccess:
            return .access
        case .MegaChatErrorTypeExist:
            return .alreadyExists
        default:
            return .generic
        }
    }
}
