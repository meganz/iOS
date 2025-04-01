import Foundation
import MEGADomain

public extension Array where Element == VideoPlaylistEntity {
    
    /// A mapping function from `[VideoPlaylistEntity]` to `[SetEntity]`
    /// - Returns: `[SetEntity]` representation of `[VideoPlaylistEntity]`
    /// Important: Some properties might uses default value due to unavailable mapping found.
    func toSetEntities(currentUserHandle: HandleEntity) -> [SetEntity] {
        map { $0.toSetEntity(currentUserHandle: currentUserHandle) }
    }
}

public extension VideoPlaylistEntity {
    
    /// A mapping function from `VideoPlaylistEntity` to `SetEntity`
    /// - Returns: `SetEntity` representation of `VideoPlaylistEntity`
    /// - Important: Some properties might uses default value due to unavailable mapping found.
    func toSetEntity(currentUserHandle: HandleEntity) -> SetEntity {
        SetEntity(
            setIdentifier: setIdentifier,
            userId: currentUserHandle,
            coverId: .invalidHandle, // video playlist set does not use cover from SDK
            creationTime: creationTime,
            modificationTime: modificationTime,
            setType: .playlist,
            name: name,
            isExported: isLinkShared,
            changeTypes: []
        )
    }
}

