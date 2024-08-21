import Foundation

public struct SharedCollectionEntity: Sendable, Equatable {
    public let `set`: SetEntity
    public let setElements: [SetElementEntity]
    
    public init(set: SetEntity, setElements: [SetElementEntity]) {
        self.set = set
        self.setElements = setElements
    }
}

extension SharedCollectionEntity: Identifiable {
    public var id: HandleEntity { `set`.handle }
}
