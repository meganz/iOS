import MEGADomain
import MEGASdk

extension MEGASet {
    public func toSetEntity() -> SetEntity {
        SetEntity(set: self)
    }
}

extension Array where Element: MEGASet {
    public func toSetEntities() -> [SetEntity] {
        map { $0.toSetEntity() }
    }
}

fileprivate extension SetEntity {
    init(set: MEGASet) {
        self.init(
            handle: set.handle,
            userId: set.userId,
            coverId: set.cover,
            creationTime: set.timestampCreated ?? Date(),
            modificationTime: set.timestamp ?? Date(),
            setType: set.type.toSetTypeEntity(),
            name: set.name ?? "",
            isExported: set.isExported(),
            changeTypes: set.changes().toChangeTypeEntity()
        )
    }
}
