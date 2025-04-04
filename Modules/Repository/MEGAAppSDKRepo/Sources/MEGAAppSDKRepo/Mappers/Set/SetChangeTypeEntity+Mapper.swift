import MEGADomain
import MEGASdk

extension MEGASetChangeType {
    public func toChangeTypeEntity() -> SetChangeTypeEntity {
        SetChangeTypeEntity(rawValue: rawValue)
    }
}
