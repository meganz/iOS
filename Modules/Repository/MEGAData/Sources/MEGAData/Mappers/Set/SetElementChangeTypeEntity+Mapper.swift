import MEGASdk
import MEGADomain

extension MEGASetElementChangeType {
    public func toChangeTypeEntity() -> SetElementChangeTypeEntity {
        SetElementChangeTypeEntity(rawValue: rawValue)
    }
}
