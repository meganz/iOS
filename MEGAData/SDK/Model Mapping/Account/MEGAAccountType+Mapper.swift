import Foundation
import MEGADomain

extension MEGAAccountType {
    func toAccountTypeEntity() -> AccountTypeEntity {
        switch self {
        case .free:
            return .free
        case .proI:
            return .proI
        case .proII:
            return .proII
        case .proIII:
            return .proIII
        case .lite:
            return .lite
        case .business:
            return .business
        @unknown default:
            return .free
        }
    }
}
