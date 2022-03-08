import Foundation
@testable import MEGA

extension NodeEntity {
    init(handle: MEGAHandle = .invalid, isFile: Bool = false, isFolder: Bool = false, hasThumbnail: Bool = false, label: NodeLabelTypeEntity = .unknown) {
        self.init(changeTypes: .attributes,
                  nodeType: nil,
                  name: "",
                  fingerprint: nil,
                  handle: 0,
                  base64Handle: "",
                  restoreParentHandle: 0,
                  ownerHandle: 0,
                  parentHandle: 0,
                  isFile: isFile,
                  isFolder: isFolder,
                  isRemoved: false,
                  hasThumbnail: hasThumbnail,
                  hasPreview: false,
                  isPublic: false,
                  isShare: false,
                  isOutShare: false,
                  isInShare: false,
                  isExported: false,
                  isExpired: false,
                  isTakenDown: false,
                  isFavourite: false,
                  label: label,
                  publicHandle: 0,
                  expirationTime: nil,
                  publicLinkCreationTime: nil,
                  size: 0,
                  creationTime: Date(),
                  modificationTime: Date(),
                  width: 0,
                  height: 0,
                  shortFormat: 0,
                  codecId: 0,
                  duration: 0,
                  latitude: 0,
                  longitude: 0)
    }
}
