import MEGADomain
import MEGASdk

extension SMSState {
    public func toStateEntity() -> SMSStateEntity {
        SMSStateEntity.init(rawValue: self.rawValue) ?? .notAllowed
    }
}
