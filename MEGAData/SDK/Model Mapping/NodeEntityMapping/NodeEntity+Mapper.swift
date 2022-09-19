import Foundation
import MEGADomain

extension NodeEntity {
    func toMEGANode(in sdk: MEGASdk) -> MEGANode? {
        sdk.node(forHandle: handle)
    }
}

extension Array where Element == NodeEntity {
    func toMEGANodes(in sdk: MEGASdk) -> [MEGANode] {
        compactMap { $0.toMEGANode(in: sdk) }
    }
}

extension Array where Element: MEGANode {
    func toNodeEntities() -> [NodeEntity] {
        map { $0.toNodeEntity() }
    }
}

extension MEGANode {
    func toNodeEntity() -> NodeEntity {
        NodeEntity(node: self)
    }
}

fileprivate extension NodeEntity {
    init(node: MEGANode) {
        self.init(
            // MARK: - Types
            changeTypes                        : ChangeTypeEntity(rawValue: node.getChanges().rawValue),
            nodeType                           : NodeTypeEntity(nodeType: node.type),
            
            // MARK: - Identification
            name                               : node.name ?? "",
            fingerprint                        : node.fingerprint,
            
            // MARK: - Handles
            handle                             : node.handle,
            base64Handle                       : node.base64Handle ?? "",
            restoreParentHandle                : node.restoreHandle,
            ownerHandle                        : node.owner,
            parentHandle                       : node.parentHandle,
            
            // MARK: - Attributes
            isFile                             : node.isFile(),
            isFolder                           : node.isFolder(),
            isRemoved                          : node.isRemoved(),
            hasThumbnail                       : node.hasThumbnail(),
            hasPreview                         : node.hasPreview(),
            isPublic                           : node.isPublic(),
            isShare                            : node.isShared(),
            isOutShare                         : node.isOutShare(),
            isInShare                          : node.isInShare(),
            isExported                         : node.isExported(),
            isExpired                          : node.isExpired(),
            isTakenDown                        : node.isTakenDown(),
            isFavourite                        : node.isFavourite,
            label                              : node.label.toNodeLabelTypeEntity(),
            
            // MARK: - Links
            publicHandle                       : node.publicHandle,
            expirationTime                     : Date(timeIntervalSince1970: TimeInterval(node.expirationTime)),
            publicLinkCreationTime             : node.publicLinkCreationTime,

            // MARK: - Files
            size                               : node.size?.uint64Value ?? 0,
            creationTime                       : node.creationTime ?? Date(),
            modificationTime                   : node.modificationTime ?? Date(),

            // MARK: - Media
            width                              : node.width,
            height                             : node.height,
            shortFormat                        : node.shortFormat,
            codecId                            : node.videoCodecId,
            duration                           : node.duration,

            // MARK: - Photo
            latitude                           : node.latitude?.doubleValue,
            longitude                          : node.longitude?.doubleValue,
            
            // MARK: - Backup
            deviceId                           : node.deviceId
        )
    }
}
