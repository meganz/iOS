import Foundation
import MEGADomain

extension Array where Element == AlbumEntity {
    
    /// A mapping function from `[AlbumEntity]` to `[SetEntity]`
    /// - Returns: `[SetEntity]` representation of `[AlbumEntity]`
    /// Important: Some properties might uses default value due to unavailable mapping found.
    func toSetEntities(currentUserHandle: HandleEntity) -> [SetEntity] {
        map { $0.toSetEntity(currentUserHandle: currentUserHandle) }
    }
}

extension AlbumEntity {
    
    /// A mapping function from `AlbumEntity` to `SetEntity`
    /// - Returns: `SetEntity` representation of `AlbumEntity`
    /// - Important: Some properties might uses default value due to unavailable mapping found.
    func toSetEntity(currentUserHandle: HandleEntity) -> SetEntity {
        SetEntity(
            setIdentifier: setIdentifier,
            userId: currentUserHandle,
            coverId: coverNode?.handle ?? .invalidHandle,
            creationTime: creationTime ?? Date.now,
            modificationTime: modificationTime ?? Date.now,
            setType: .album,
            name: name,
            isExported: isLinkShared,
            changeTypes: []
        )
    }
}
