import Foundation
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGASwift
import UIKit

protocol NodeThumbnailHomeUseCaseProtocol: Sendable {
    func loadThumbnail(
        of nodeHandle: HandleEntity,
        completion: @escaping (UIImage?) -> Void
    )
}

struct NodeThumbnailHomeUseCase: NodeThumbnailHomeUseCaseProtocol {

    private var sdkNodeClient: SDKNodeClient
    private var fileSystemClient: FileSystemImageCacheClient
    private var thumbnailRepo: any ThumbnailRepositoryProtocol

    init(
        sdkNodeClient: SDKNodeClient,
        fileSystemClient: FileSystemImageCacheClient,
        thumbnailRepo: any ThumbnailRepositoryProtocol
    ) {
        self.sdkNodeClient = sdkNodeClient
        self.fileSystemClient = fileSystemClient
        self.thumbnailRepo = thumbnailRepo
    }

    func loadThumbnail(
        of nodeHandle: HandleEntity,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let node = sdkNodeClient.findNode(nodeHandle) else {
            completion(nil)
            return
        }
        asyncOnGlobal {
            downloadthumbnailForNode(node, completion: completion)
        }
    }

    fileprivate func downloadthumbnailForNode(_ node: NodeEntity, completion: @escaping (UIImage?) -> Void) {
        switch node.hasThumbnail {
        case true:
            loadThumbnailForThumbnailedNode(of: node.handle, base64Handle: node.base64Handle, completion: completion)
        case false:
            loadThumbnailForNonThumbnailedNode(of: node.handle, completion: completion)
        }
    }

    private func loadThumbnailForThumbnailedNode(
        of nodeHandle: HandleEntity,
        base64Handle: Base64HandleEntity,
        completion: @escaping (UIImage?) -> Void
    ) {
        let destinationThumbnailCachePath = thumbnailRepo.generateCachingURL(for: base64Handle, type: .thumbnail)
        let fileExists = fileSystemClient.fileExists(destinationThumbnailCachePath)
        if fileExists {
            fileSystemClient.loadCachedImageAsync(destinationThumbnailCachePath) { cachedImageData in
                completion(cachedImageData.flatMap(UIImage.init(data:)))
            }
            return
        }

        sdkNodeClient.loadThumbnail(nodeHandle, destinationThumbnailCachePath) { finished in
            guard finished else {
                completion(nil)
                return
            }
            fileSystemClient.loadCachedImageAsync(destinationThumbnailCachePath) { newlyDownloadedImageData in
                completion(newlyDownloadedImageData.flatMap(UIImage.init(data:)))
            }
        }
    }

    private func loadThumbnailForNonThumbnailedNode(
        of nodeHandle: HandleEntity,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let node = sdkNodeClient.findNode(nodeHandle) else {
            completion(nil)
            return
        }
        switch node.nodeType {
        case .folder:
            loadThumbnailForFolderNode(node, completion: completion)
        case .file:
            loadThumbnailForFileNode(node.name, completion: completion)
        default:
            completion(UIImage.mnz_generic())
        }
    }

    fileprivate func loadThumbnailForFolderNode(
        _ node: NodeEntity,
        completion: @escaping (UIImage?) -> Void
    ) {
        if node.name == MEGACameraUploadsNodeName {
            completion(UIImage.mnz_folderCameraUploads())
            return
        }
        if node.name == Strings.Localizable.myChatFiles {
            sdkNodeClient.findChatFolderNode { chatFilesRootNode in
                guard chatFilesRootNode?.handle == node.handle else {
                    completion(self.defaultFolderImage(forNode: node))
                    return
                }
                completion(UIImage.mnz_folderMyChatFiles())
            }
            return
        }
        
        completion(defaultFolderImage(forNode: node))
    }

    fileprivate func loadThumbnailForFileNode(
        _ nodeName: String,
        completion: @escaping (UIImage?) -> Void
    ) {
        let fileTypeImageResource: UIImage = MEGAAssetsImageProvider.fileTypeResource(forFileExtension: nodeName.pathExtension)
        completion(fileTypeImageResource)
    }

    private func defaultFolderImage(forNode node: NodeEntity) -> UIImage? {
        guard node.isFolder else { return nil }
        if node.isInShare { return UIImage.mnz_incomingFolder() }
        if node.isOutShare { return UIImage.mnz_outgoingFolder() }
        return UIImage(resource: .filetypeFolder)
    }
}
