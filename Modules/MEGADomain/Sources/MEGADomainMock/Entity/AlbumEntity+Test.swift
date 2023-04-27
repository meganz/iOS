import Foundation
import MEGADomain

public extension AlbumEntity {
    init(id: HandleEntity,
         name: String = "",
         coverNode: NodeEntity? = nil,
         count: Int = 0,
         type: AlbumEntityType,
         modificationTime: Date? = nil,
         isTesting: Bool = true) {
        self.init(id: id, name: name, coverNode: coverNode, count: count, type: type, modificationTime: modificationTime)
    }
}
