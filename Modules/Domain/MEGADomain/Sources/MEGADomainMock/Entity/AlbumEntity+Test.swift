import Foundation
import MEGADomain

public extension AlbumEntity {
    init(id: HandleEntity,
         name: String = "",
         coverNode: NodeEntity? = nil,
         count: Int = 0,
         type: AlbumEntityType,
         creationTime: Date? = nil,
         modificationTime: Date? = nil,
         sharedLinkStatus: SharedLinkStatusEntity = .unavailable,
         isTesting: Bool = true) {
        self.init(id: id, name: name, coverNode: coverNode, count: count, type: type, creationTime: creationTime, modificationTime: modificationTime, sharedLinkStatus: sharedLinkStatus)
    }
}
