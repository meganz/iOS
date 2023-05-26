import Foundation

public struct SharedAlbumEntity {
    public let `set`: SetEntity
    public let setElements: [SetElementEntity]
    
    public init(set: SetEntity, setElements: [SetElementEntity]) {
        self.set = set
        self.setElements = setElements
    }
}

extension SharedAlbumEntity: Identifiable {
    public var id: HandleEntity { `set`.handle }
}
