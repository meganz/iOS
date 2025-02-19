import Foundation
import MEGADomain
import MEGASDKRepo
import MEGASwift

protocol NodeInfoRepositoryProtocol: Sendable {
    func childrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]?
    func folderChildrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]?
    func node(fromHandle: HandleEntity) -> MEGANode?
    func folderLinkLogout()
    
    /// Used for check wethere a node from a non current user folder link is got take down or not.
    /// - Parameter node: node to check
    /// - Returns: returns a either is take down or not
    func isFolderLinkNodeTakenDown(node: MEGANode) async throws -> Bool
}

final class NodeInfoRepository: NodeInfoRepositoryProtocol {
    private let sdk: MEGASdk
    private let folderSDK: MEGASdk
    private let megaStore: MEGAStore
    private let streamingInfoRepository: any StreamingInfoRepositoryProtocol
    private let offlineFileInfoRepository: any OfflineInfoRepositoryProtocol
    private let sortingPreference: PreferenceWrapper<SortingPreference> = PreferenceWrapper(key: .sortingPreference, defaultValue: .perFolder, useCase: PreferenceUseCase.default)
    private let sortingType: PreferenceWrapper<MEGASortOrderType> = PreferenceWrapper(key: .sortingPreferenceType, defaultValue: .defaultAsc, useCase: PreferenceUseCase.default)
    
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
    private func playableChildren(of parent: HandleEntity) -> [MEGANode]? {
        guard let parentNode = sdk.node(forHandle: parent) else { return nil }
        
        return sdk.children(forParent: parentNode, order: sortType(for: parent)).toNodeArray()
            .filter { $0.name?.fileExtensionGroup.isMultiMedia == true &&
                $0.name?.fileExtensionGroup.isVideo == false &&
                $0.mnz_isPlayable() }
    }
    
    private func folderPlayableChildren(of parent: HandleEntity) -> [MEGANode]? {
        guard let parentNode = folderNode(fromHandle: parent) else { return nil }
        
        return folderSDK.children(forParent: parentNode, order: sortType(for: parent)).toNodeArray()
            .filter { $0.name?.fileExtensionGroup.isMultiMedia == true &&
                $0.name?.fileExtensionGroup.isVideo == false &&
                $0.mnz_isPlayable() }
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

    private func folderNode(fromHandle: HandleEntity) -> MEGANode? { folderSDK.node(forHandle: fromHandle) }
    
    private func folderAuthNode(fromNode: MEGANode) -> MEGANode? { folderSDK.authorizeNode(fromNode) }

    func info(fromNodes: [MEGANode]?) -> [AudioPlayerItem]? {
        return fromNodes?.compactMap {
            guard let url = path(fromHandle: $0.handle),
                  let name = $0.name else { return nil }
            return AudioPlayerItem(name: name, url: url, node: $0, hasThumbnail: $0.hasThumbnail())
        }
    }

    private func authInfo(fromNodes: [MEGANode]?) -> [AudioPlayerItem]? {
        return fromNodes?.compactMap {
            guard let node = folderAuthNode(fromNode: $0),
                  let name = node.name,
                  let url = streamingInfoRepository.path(fromNode: node) else { return nil }
            return AudioPlayerItem(name: name, url: url, node: node, hasThumbnail: $0.hasThumbnail())
        }
    }

    // MARK: - Public functions
    func node(fromHandle: HandleEntity) -> MEGANode? { sdk.node(forHandle: fromHandle) }
    
    func path(fromHandle: HandleEntity) -> URL? {
        guard let node = node(fromHandle: fromHandle) else { return nil }
        
        return offlineFileInfoRepository.localPath(fromNode: node) ?? streamingInfoRepository.path(fromNode: node)
    }
    
    func childrenInfo(fromParentHandle: HandleEntity) -> [AudioPlayerItem]? {
        playableChildren(of: fromParentHandle).flatMap(info)
    }
    
    func folderChildrenInfo(fromParentHandle parent: HandleEntity) -> [AudioPlayerItem]? {
        folderPlayableChildren(of: parent).flatMap(authInfo)
    }
     
    func folderLinkLogout() {
        folderSDK.logout()
    }
    
    func isFolderLinkNodeTakenDown(node: MEGANode) async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            folderSDK.getDownloadUrl(node, singleUrl: true, delegate: RequestDelegate { result in
                switch result {
                case .failure(let error):
                    guard case .apiEBlocked = error.type else {
                        completion(.failure(error))
                        return
                    }
                    completion(.success(true))
                case .success:
                    completion(.success(false))
                }
            })
        }
    }
}
