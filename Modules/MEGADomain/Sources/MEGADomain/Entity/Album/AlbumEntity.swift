import Foundation

public enum AlbumEntityType: Sendable {
    case favourite
    case raw
    case gif
    case user
}

public struct AlbumEntity: Identifiable, Hashable, Sendable {
    public let id: HandleEntity
    public let name: String
    public var coverNode: NodeEntity?
    public let count: Int
    public let type: AlbumEntityType
    public let modificationTime: Date?
    
    public init(id: HandleEntity, name: String, coverNode: NodeEntity?, count: Int, type: AlbumEntityType, modificationTime: Date? = nil) {
        self.id = id
        self.name = name
        self.coverNode = coverNode
        self.count = count
        self.type = type
        self.modificationTime = modificationTime
    }
}

extension AlbumEntity {
    public func update(name newName: String) -> AlbumEntity {
        AlbumEntity(id: self.id, name: newName, coverNode: self.coverNode, count: self.count, type: self.type, modificationTime: self.modificationTime)
    }
    
    public var systemAlbum: Bool {
        type == .raw || type == .gif || type == .favourite
    }
}
