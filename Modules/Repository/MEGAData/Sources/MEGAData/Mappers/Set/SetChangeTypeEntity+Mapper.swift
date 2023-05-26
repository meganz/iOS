import MEGASdk
import MEGADomain

extension MEGASetChangeType {
    public func toChangeTypeEntity() -> SetChangeTypeEntity {
        SetChangeTypeEntity(rawValue: rawValue)
    }
}
