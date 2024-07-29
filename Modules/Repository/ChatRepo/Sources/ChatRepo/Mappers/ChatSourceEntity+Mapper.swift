import MEGAChatSdk
import MEGADomain

extension MEGAChatSource {
    func toChatSourceEntity() -> ChatSourceEntity {
        switch self {
        case .invalidChat:
                .invalidChat
        case .error:
                .error
        case .none:
                .none
        case .local:
                .local
        case .remote:
                .remote
        @unknown default:
                .error
        }
    }
}
