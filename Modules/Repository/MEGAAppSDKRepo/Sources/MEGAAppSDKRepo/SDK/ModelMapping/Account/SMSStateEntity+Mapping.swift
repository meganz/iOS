import MEGADomain
import MEGASdk

extension SMSState {
    public func toStateEntity() -> SMSStateEntity {
        SMSStateEntity(rawValue: self.rawValue) ?? .notAllowed
    }
}

extension SMSStateEntity {
    public func toSMSState() -> SMSState {
        SMSState(rawValue: self.rawValue) ?? .notAllowed
    }
}
