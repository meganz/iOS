import MEGADomain
import MEGAPresentation
import MEGASDKRepo

@objc final class BrowserViewModel: NSObject {
    private let isChildBrowser: Bool
    private let isSelectVideos: Bool
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let sdk: MEGASdk
    private var parentNode: MEGANode?
    
    private var parentNodeHandle: MEGAHandle? {
        if let parentNode {
            parentNode.handle
        } else if !isChildBrowser {
            sdk.rootNode?.handle
        } else {
            nil
        }
    }
    
    init(parentNode: MEGANode?,
         isChildBrowser: Bool,
         isSelectVideos: Bool,
         sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
         sdk: MEGASdk = .shared) {
        self.parentNode = parentNode
        self.isChildBrowser = isChildBrowser
        self.isSelectVideos = isSelectVideos
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.sdk = sdk
    }
    
    func updateParentNode(_ node: MEGANode?) {
        parentNode = node
    }
    
    @objc func nodesForParent() async -> MEGANodeList {
        guard let parentNodeHandle else {
            return MEGANodeList()
        }
        
        let excludeSensitive = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        let filter = MEGASearchFilter(
            term: "",
            parentNodeHandle: parentNodeHandle,
            nodeType: .unknown,
            category: .unknown,
            sensitiveFilter: excludeSensitive ? .nonSensitiveOnly : .disabled,
            favouriteFilter: .disabled,
            creationTimeFrame: nil,
            modificationTimeFrame: nil
        )
        let nodeList = sdk.searchNonRecursively(with: filter,
                                                orderType: .defaultAsc,
                                                page: nil,
                                                cancelToken: MEGACancelToken())
        return if isSelectVideos {
            filterForVideoAndFolders(nodeList: nodeList)
        } else {
            nodeList
        }
    }
    
    private func filterForVideoAndFolders(nodeList: MEGANodeList) -> MEGANodeList {
        let newNodeList = MEGANodeList()
        for index in 0..<nodeList.size {
            if let node = nodeList.node(at: index),
               node.isFolder() || node.name?.fileExtensionGroup.isVideo == true {
                newNodeList.add(node)
            }
        }
        return newNodeList
    }
}
