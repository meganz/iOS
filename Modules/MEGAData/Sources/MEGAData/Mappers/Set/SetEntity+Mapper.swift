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
        self.init(handle            : set.handle,
                  userId            : set.userId,
                  coverId           : set.cover,
                  modificationTime  : set.timestamp,
                  name              : set.name ?? "",
                  isExported        : set.isExported(),
                  changes           : set.changes().toChangesEntity()
        )
    }
}
