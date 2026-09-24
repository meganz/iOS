import MEGADomain
import MEGASdk

public struct AudioFolderLinkNodeRepository: AudioFolderLinkNodeRepositoryProtocol {
    public static var newRepo: AudioFolderLinkNodeRepository {
        AudioFolderLinkNodeRepository(folderSDK: .sharedFolderLinkSdk)
    }

    private let folderSDK: MEGASdk

    public init(folderSDK: MEGASdk) {
        self.folderSDK = folderSDK
    }

    public func authorizedNode(forHandle handle: HandleEntity) -> (any PlayableNode)? {
        guard let node = folderSDK.node(forHandle: handle) else { return nil }
        return folderSDK.authorizeNode(node) ?? node
    }
}
