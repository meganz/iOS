import MEGADomain
import MEGASdk

extension Array where Element == NodeEntity {
    public func toPhotosBrowserEntities() -> [PhotosBrowserLibraryEntity] {
        map { $0.toPhotosBrowserEntity() }
    }
}

extension NodeEntity {
    public func toPhotosBrowserEntity() -> PhotosBrowserLibraryEntity {
        .init(handle: handle, base64Handle: base64Handle, name: name, modificationTime: modificationTime)
    }
}

extension Array where Element == MEGANode {
    public func toPhotosBrowserEntities() -> [PhotosBrowserLibraryEntity] {
        map { $0.toPhotosBrowserEntity() }
    }
}

extension MEGANode {
    public func toPhotosBrowserEntity() -> PhotosBrowserLibraryEntity {
        .init(handle: handle, base64Handle: base64Handle ?? "", name: name ?? "", modificationTime: modificationTime ?? Date())
    }
}
