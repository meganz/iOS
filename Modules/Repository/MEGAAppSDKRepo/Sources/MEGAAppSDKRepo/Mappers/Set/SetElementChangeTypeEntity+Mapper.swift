import MEGADomain
import MEGASdk

extension MEGASetElementChangeType {
    public func toChangeTypeEntity() -> SetElementChangeTypeEntity {
        SetElementChangeTypeEntity(rawValue: rawValue)
    }
}
