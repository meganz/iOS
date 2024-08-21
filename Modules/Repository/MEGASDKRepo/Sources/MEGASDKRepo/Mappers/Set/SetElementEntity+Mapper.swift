import MEGADomain
import MEGASdk

extension MEGASetElement {
    public func toSetElementEntity() -> SetElementEntity {
        SetElementEntity(setElement: self)
    }
}

extension Array where Element: MEGASetElement {
    public func toSetElementsEntities() -> [SetElementEntity] {
        map { $0.toSetElementEntity() }
    }
}

fileprivate extension SetElementEntity {
    init(setElement: MEGASetElement) {
        self.init(
            handle: setElement.handle,
            ownerId: setElement.ownerId,
            order: setElement.order,
            nodeId: setElement.nodeId,
            modificationTime: setElement.timestamp ?? Date(),
            name: setElement.name ?? "",
            changeTypes: setElement.changes().toChangeTypeEntity()
        )
    }
}
