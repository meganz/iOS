import MEGADomain
import MEGAPresentation
import MEGASDKRepo

@objc final class BrowserViewModel: NSObject {
    private let isChildBrowser: Bool
    private let isSelectVideos: Bool
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let sdk: MEGASdk
    private let featureFlagProvider: any FeatureFlagProviderProtocol
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
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         sdk: MEGASdk = .shared,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.parentNode = parentNode
        self.isChildBrowser = isChildBrowser
        self.isSelectVideos = isSelectVideos
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.sdk = sdk
        self.featureFlagProvider = featureFlagProvider
    }
    
    func updateParentNode(_ node: MEGANode?) {
        parentNode = node
    }
    
    @objc func nodesForParent() async -> MEGANodeList {
        guard let parentNodeHandle else {
            return MEGANodeList()
        }
        
        let excludeSensitive = await shouldExcludeSensitiveItems()
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
    
    private func shouldExcludeSensitiveItems() async -> Bool {
        if featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) {
            await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        } else {
            false
        }
    }
}
