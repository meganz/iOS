import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGASwift

protocol NodeInfoRepositoryProtocol: Sendable {
    /// Fetches audio tracks contained in a folder owned/accessible by the current account. The `folder` handle identifies a MEGA folder. The implementation resolves its contents (files and/or subfolders) and returns only files that are suitable for audio playback.
    /// - Parameter folder: The `HandleEntity` of the target folder in the current account context.
    /// - Returns: An array of `AudioPlayerItem` representing audio tracks in the folder, or `nil` if the folder does not exist or cannot be read.
    func fetchAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]?
    
    /// Fetches audio tracks from a folder-link context. The `folder` handle refers to a folder-link. Tracks are resolved and authorized for playback before being returned as `AudioPlayerItem`s.
    /// - Parameter folder: The `HandleEntity` of the folder-link.
    /// - Returns: An array of authorized `AudioPlayerItem` for playback, or `nil` if the folder is unavailable or cannot be read.
    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]?
    
    /// Resolves a `MEGANode` for the given handle in the current account context.
    /// - Parameter handle: The `HandleEntity` to look up.
    /// - Returns: The resolved `MEGANode` if found; otherwise `nil`.
    func node(for handle: HandleEntity) -> MEGANode?
    
    /// Ends the active folder-link session (if any) for the repository.
    func folderLinkLogout()
    
    /// Used to check whether a node from a non-current user folder link has been taken down or not.
    /// - Parameter node: Node to check.
    /// - Returns: `true` if the node has been taken down; `false` otherwise.
    /// - Throws: An error if the check cannot be completed.
    func isFolderLinkNodeTakenDown(node: MEGANode) async throws -> Bool
    
    /// Determines whether the given node has been taken down via API.
    /// This covers both:
    /// 1. Nodes owned by the current user.
    /// 2. Nodes imported from file or folder-links (which themselves may have been subsequently removed).
    /// - Parameter node: Node to check.
    /// - Returns: `true` if the node has been taken down; `false` otherwise.
    /// - Throws: An error if the check cannot be completed.
    func isNodeTakenDown(node: MEGANode) async throws -> Bool
}

final class NodeInfoRepository: NodeInfoRepositoryProtocol {
    private let sdk: MEGASdk
    private let folderSDK: MEGASdk
    private let megaStore: MEGAStore
    private let streamingInfoRepository: any StreamingInfoRepositoryProtocol
    private let offlineFileInfoRepository: any OfflineInfoRepositoryProtocol
    private let sortingPreference: PreferenceWrapper<SortingPreference, PreferenceKeyEntity> = PreferenceWrapper(key: .sortingPreference, defaultValue: .perFolder, useCase: PreferenceUseCase.default)
    private let sortingType: PreferenceWrapper<MEGASortOrderType, PreferenceKeyEntity> = PreferenceWrapper(key: .sortingPreferenceType, defaultValue: .defaultAsc, useCase: PreferenceUseCase.default)
    
    init(
        sdk: MEGASdk = MEGASdk.shared,
        folderSDK: MEGASdk = MEGASdk.sharedFolderLink,
        megaStore: MEGAStore = MEGAStore.shareInstance(),
        offlineFileInfoRepository: any OfflineInfoRepositoryProtocol = OfflineInfoRepository(),
        streamingInfoRepository: any StreamingInfoRepositoryProtocol = StreamingInfoRepository()
    ) {
        self.sdk = sdk
        self.folderSDK = folderSDK
        self.megaStore = megaStore
        self.offlineFileInfoRepository = offlineFileInfoRepository
        self.streamingInfoRepository = streamingInfoRepository
    }
    
    // MARK: - Private functions
    private func fetchAudioNodes(inFolder folder: HandleEntity, using sdk: MEGASdk, nodeLookup: (HandleEntity) -> MEGANode?) -> [MEGANode]? {
        guard let parentNode = nodeLookup(folder) else {
            return nil
        }
        
        return sdk.children(forParent: parentNode, order: sortType(for: folder)).toPlayableNodeArray()
    }
       
    private func fetchAudioNodes(inFolder folder: HandleEntity) -> [MEGANode]? {
        fetchAudioNodes(inFolder: folder, using: sdk) { handle in
            sdk.node(forHandle: handle)
        }
    }
    
    private func fetchFolderLinkAudioNodes(inFolder folder: HandleEntity) -> [MEGANode]? {
        fetchAudioNodes(inFolder: folder, using: folderSDK) { handle in
            folderNode(from: handle)
        }
    }
    
    private func sortType(for parent: HandleEntity) -> Int {
        guard let context = megaStore.stack.newBackgroundContext() else { return MEGASortOrderType.defaultAsc.rawValue }
        
        var sortType: Int = MEGASortOrderType.defaultAsc.rawValue
        
        context.performAndWait {
            sortType = sortingPreference.wrappedValue == .perFolder ?
            megaStore.fetchCloudAppearancePreference(handle: parent, context: context)?.sortType?.intValue ?? MEGASortOrderType.defaultAsc.rawValue :
            sortingType.wrappedValue.rawValue
        }
        
        return sortType
    }

    private func folderNode(from handle: HandleEntity) -> MEGANode? { folderSDK.node(forHandle: handle) }
    
    private func folderAuthNode(from node: MEGANode) -> MEGANode? { folderSDK.authorizeNode(node) }

    func makeAudioPlayerItems(from nodes: [MEGANode]?) -> [AudioPlayerItem]? {
        nodes?.compactMap {
            guard let url = playbackURL(for: $0.handle),
                  let name = $0.name else { return nil }
            return AudioPlayerItem(name: name, url: url, node: $0, hasThumbnail: $0.hasThumbnail())
        }
    }

    private func makeAuthorizedFolderLinkAudioPlayerItems(from nodes: [MEGANode]?) -> [AudioPlayerItem]? {
        nodes?.compactMap {
            guard let node = folderAuthNode(from: $0),
                  let name = node.name,
                  let url = streamingInfoRepository.streamingURL(for: node) else { return nil }
            return AudioPlayerItem(name: name, url: url, node: node, hasThumbnail: $0.hasThumbnail())
        }
    }

    // MARK: - Public functions
    func node(for handle: HandleEntity) -> MEGANode? { sdk.node(forHandle: handle) }
    
    func playbackURL(for handle: HandleEntity) -> URL? {
        guard let node = node(for: handle) else { return nil }
        
        if offlineFileInfoRepository.isNodeAvailableOffline(node) {
            return offlineFileInfoRepository.offlineFileURL(for: node) ?? streamingInfoRepository.streamingURL(for: node)
        } else {
            return streamingInfoRepository.streamingURL(for: node)
        }
    }
    
    func fetchAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]? {
        fetchAudioNodes(inFolder: folder).flatMap(makeAudioPlayerItems)
    }
    
    func fetchFolderLinkAudioTracks(from folder: HandleEntity) -> [AudioPlayerItem]? {
        fetchFolderLinkAudioNodes(inFolder: folder).flatMap(makeAuthorizedFolderLinkAudioPlayerItems)
    }
     
    func folderLinkLogout() {
        folderSDK.logout()
    }
    
    private func isNodeTakenDown(
        node: MEGANode,
        using sdk: MEGASdk
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            sdk.getDownloadUrl(node, singleUrl: false, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    continuation.resume(returning: false)
                case .failure(let error) where error.type == .apiEBlocked:
                    continuation.resume(returning: true)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    func isNodeTakenDown(node: MEGANode) async throws -> Bool {
        try await isNodeTakenDown(node: node, using: sdk)
    }

    func isFolderLinkNodeTakenDown(node: MEGANode) async throws -> Bool {
        try await isNodeTakenDown(node: node, using: folderSDK)
    }
}
