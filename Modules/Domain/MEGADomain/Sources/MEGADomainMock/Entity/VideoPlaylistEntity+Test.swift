import Foundation
import MEGADomain

public extension VideoPlaylistEntity {
    init(
        setIdentifier: SetIdentifier,
        name: String = "",
        coverNode: NodeEntity? = nil,
        count: Int = 0,
        type: VideoPlaylistEntityType = .favourite,
        creationTime: Date = Date(),
        modificationTime: Date = Date(),
        sharedLinkStatus: SharedLinkStatusEntity = .unavailable,
        isTesting: Bool = true
    ) {
        self.init(
            setIdentifier: setIdentifier,
            name: name,
            coverNode: coverNode,
            count: count,
            type: type,
            creationTime: creationTime,
            modificationTime: modificationTime,
            sharedLinkStatus: sharedLinkStatus)
    }
}
