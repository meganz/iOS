import MEGADomain

extension MEGASet {
    func toSetEntity() -> SetEntity {
        SetEntity(set: self)
    }
}

extension Array where Element: MEGASet {
    func toSetEntities() -> [SetEntity] {
        map { $0.toSetEntity() }
    }
}

fileprivate extension SetEntity {
    init(set: MEGASet) {
        self.init(handle            :set.handle,
                  userId            :set.userId,
                  coverId           :set.cover,
                  modificationTime  :set.timestamp,
                  name              :set.name ?? ""
        )
    }
}
