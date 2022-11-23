import MEGADomain

extension MEGASetElement {
    func toSetElementEntity() -> SetElementEntity {
        SetElementEntity(setElement: self)
    }
}

extension Array where Element: MEGASetElement {
    func toSetElementsEntities() -> [SetElementEntity] {
        map { $0.toSetElementEntity() }
    }
}

fileprivate extension SetElementEntity {
    init(setElement: MEGASetElement) {
        self.init(handle            :setElement.handle,
                  order             :setElement.order,
                  nodeId            :setElement.nodeId,
                  modificationTime  :setElement.timestamp,
                  name              :setElement.name ?? ""
        )
    }
}
