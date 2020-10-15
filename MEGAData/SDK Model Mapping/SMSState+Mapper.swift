import Foundation

extension SMSState {
    func toStateEntity() -> SMSStateEntity {
        SMSStateEntity.init(rawValue: self.rawValue) ?? .notAllowed
    }
}
