extension NodeEntity {

    init(with node: MEGANode) {

        // MARK: - Types
        self.changeTypes                        = ChangeType.init(rawValue: node.getChanges().rawValue)
        self.nodeType                           = NodeType(with: node.type)

        // MARK: - Identification

        self.name                               = node.name
        self.tag                                = node.tag
        self.fingerprint                        = node.fingerprint

        // MARK: - Handles

        self.handle                             = node.handle
        self.base64Handle                       = node.base64Handle
        self.ownerHandle                        = node.owner
        self.restoreParentHandle                = node.restoreHandle

        // MARK: - Attributes

        self.isFile                             = node.isFile()
        self.isFolder                           = node.isFolder()
        self.isRemoved                          = node.isRemoved()
        self.hasThumnail                        = node.hasThumbnail()
        self.hasPreview                         = node.hasPreview()
        self.isPublic                           = node.isPublic()
        self.isShare                            = node.isShared()
        self.isOutShare                         = node.isOutShare()
        self.isInShare                          = node.isInShare()
        self.isExported                         = node.isExported()
        self.isExpired                          = node.isExpired()
        self.isTakenDown                        = node.isTakenDown()

        // MARK: - Links

        self.publicHandle                       = node.publicHandle
        self.expirationTime                     = Date(timeIntervalSince1970: TimeInterval(node.expirationTime))
        self.publicLinkCreationTime             = node.publicLinkCreationTime

        // MARK: - Files

        self.size                               = node.size.decimalValue
        self.createTime                         = node.creationTime
        self.modificationTime                   = node.modificationTime

        // MARK: - Media

        self.width                              = node.width
        self.height                             = node.height
        self.shortFormat                        = node.shortFormat
        self.codecId                            = node.videoCodecId
        self.duration                           = node.duration

        // MARK: - Photo

        self.latitude                           = node.latitude?.doubleValue
        self.longitude                          = node.longitude?.doubleValue
    }
}
