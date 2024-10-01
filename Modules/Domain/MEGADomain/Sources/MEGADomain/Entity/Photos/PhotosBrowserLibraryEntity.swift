import Foundation

public struct PhotosBrowserLibraryEntity: Sendable {
    public let handle: HandleEntity
    public let base64Handle: String
    public let modificationTime: Date
    
    public var name: String
    
    public init(handle: HandleEntity, base64Handle: String, name: String, modificationTime: Date) {
        self.handle = handle
        self.base64Handle = base64Handle
        self.name = name
        self.modificationTime = modificationTime
    }
}

extension PhotosBrowserLibraryEntity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(handle)
    }
}
