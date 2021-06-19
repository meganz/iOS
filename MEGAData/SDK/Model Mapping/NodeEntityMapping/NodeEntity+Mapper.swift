extension NodeEntity {
    @objc convenience init(node: MEGANode) {
        self.init(
            // MARK: - Types
            
            changeTypes                        : ChangeTypeEntity(rawValue: node.getChanges().rawValue),
            nodeType                           : NodeTypeEntity(nodeType: node.type),
            
            // MARK: - Identification
            
            name                               : node.name,
            tag                                : node.tag,
            fingerprint                        : node.fingerprint,
            
            // MARK: - Handles
            
            handle                             : node.handle,
            base64Handle                       : node.base64Handle,
            ownerHandle                        : node.owner,
            restoreParentHandle                : node.restoreHandle,
            parentHandle                       : node.parentHandle,
            
            // MARK: - Attributes
            
            isFile                             : node.isFile(),
            isFolder                           : node.isFolder(),
            isRemoved                          : node.isRemoved(),
            hasThumnail                        : node.hasThumbnail(),
            hasPreview                         : node.hasPreview(),
            isPublic                           : node.isPublic(),
            isShare                            : node.isShared(),
            isOutShare                         : node.isOutShare(),
            isInShare                          : node.isInShare(),
            isExported                         : node.isExported(),
            isExpired                          : node.isExpired(),
            isTakenDown                        : node.isTakenDown(),
            
            // MARK: - Links

            publicHandle                       : node.publicHandle,
            expirationTime                     : Date(timeIntervalSince1970: TimeInterval(node.expirationTime)),
            publicLinkCreationTime             : node.publicLinkCreationTime,

            // MARK: - Files

            size                               : node.size.uint64Value,
            createTime                         : node.creationTime,
            modificationTime                   : node.modificationTime,

            // MARK: - Media

            width                              : node.width,
            height                             : node.height,
            shortFormat                        : node.shortFormat,
            codecId                            : node.videoCodecId,
            duration                           : node.duration,

            // MARK: - Photo

            latitude                           : node.latitude?.doubleValue,
            longitude                          : node.longitude?.doubleValue
        )
    }
}
