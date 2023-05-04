import Foundation

public enum SharedLinkStatusEntity: Sendable, Hashable {
    case unavailable
    case exported(Bool)
}
