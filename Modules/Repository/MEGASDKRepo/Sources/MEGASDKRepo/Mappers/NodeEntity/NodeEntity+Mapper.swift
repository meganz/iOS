import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

extension NodeEntity {
    public func toMEGANode(in sdk: MEGASdk) -> MEGANode? {
        sdk.node(forHandle: handle)
    }
}

extension Array where Element == NodeEntity {
    public func toMEGANodes(in sdk: MEGASdk) -> [MEGANode] {
        compactMap { $0.toMEGANode(in: sdk) }
    }
}

extension Array where Element: MEGANode {
    public func toNodeEntities() -> [NodeEntity] {
        map { $0.toNodeEntity() }
    }
}

extension MEGANode {
    public func toNodeEntity() -> NodeEntity {
        NodeEntity(node: self)
    }
}

fileprivate extension NodeEntity {
    init(node: MEGANode) {
        self.init(
            // swiftlint:disable colon
            // MARK: - Types
            changeTypes                        : ChangeTypeEntity(rawValue: node.getChanges().rawValue),
            nodeType                           : node.type.toNodeTypeEntity(),
            
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
            isMarkedSensitive                  : node.isMarkedSensitive,
            description                        : node.description,
            label                              : node.label.toNodeLabelTypeEntity(),
            tags                               : node.tags?.toArray() ?? [],

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
            mediaType                          : node.name?.toMediaTypeEntity(),

            // MARK: - Photo
            latitude                           : node.latitude?.doubleValue,
            longitude                          : node.longitude?.doubleValue,
            
            // MARK: - Backup
            deviceId                           : node.deviceId
            // swiftlint:enable colon
        )
    }
}

fileprivate extension String {
    func toMediaTypeEntity() -> MediaTypeEntity? {
        if isImageType(pathExtension) {
            return .image
        } else if isVideoType(pathExtension) {
            return .video
        } else {
            return nil
        }
    }
    
    private func isImageType(_ pathExtension: String) -> Bool {
        ImageFileExtensionEntity().imagesSupportedExtensions.contains(pathExtension) ||
            RawImageFileExtensionEntity().imagesSupportedExtensions.contains(pathExtension)
    }
    
    private func isVideoType(_ pathExtension: String) -> Bool {
        VideoFileExtensionEntity().videoSupportedExtensions.contains(pathExtension)
    }
}

extension NodeEntity: @retroactive FileExtensionGroupDataSource {
    public static var fileExtensionPath: KeyPath<Self, String> { \.name.pathExtension }
}
