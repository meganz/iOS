import MEGASdk
import MEGADomain

extension MEGASetElementChanges {
    public func toChangesEntity() -> SetElementChangesEntity {
        SetElementChangesEntity(rawValue: rawValue)
    }
}
