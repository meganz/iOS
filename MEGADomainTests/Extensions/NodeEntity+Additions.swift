import Foundation
@testable import MEGA

extension NodeEntity {
    init() {
        self.init(changeTypes: .attributes, nodeType: nil, name: "", fingerprint: nil, tag: 0, handle: 0, base64Handle: "", restoreParentHandle: 0, ownerHandle: 0, parentHandle: 0, isFile: false, isFolder: false, isRemoved: false, hasThumnail: false, hasPreview: false, isPublic: false, isShare: false, isOutShare: false, isInShare: false, isExported: false, isExpired: false, isTakenDown: false, publicHandle: 0, expirationTime: nil, publicLinkCreationTime: nil, size: 0, createTime: nil, modificationTime: Date(), width: 0, height: 0, shortFormat: 0, codecId: 0, duration: 0, latitude: 0, longitude: 0)
    }
}
