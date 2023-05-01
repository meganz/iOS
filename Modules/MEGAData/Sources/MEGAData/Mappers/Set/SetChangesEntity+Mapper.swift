import MEGASdk
import MEGADomain

extension MEGASetChanges {
    public func toChangesEntity() -> SetChangesEntity {
        SetChangesEntity(rawValue: rawValue)
    }
}
