import MEGADomain
import MEGAFoundation
import MEGAPresentation
import MEGASDKRepo

@MainActor
@objc final class BrowserViewModel: NSObject {
    private let isChildBrowser: Bool
    private let isSelectVideos: Bool
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let filesSearchUseCase: any FilesSearchUseCaseProtocol
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
    
    let searchDebouncer = Debouncer(delay: 0.5)
    
    init(parentNode: MEGANode?,
         isChildBrowser: Bool,
         isSelectVideos: Bool,
         sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
         filesSearchUseCase: some FilesSearchUseCaseProtocol,
         sdk: MEGASdk = .shared) {
        self.parentNode = parentNode
        self.isChildBrowser = isChildBrowser
        self.isSelectVideos = isSelectVideos
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.filesSearchUseCase = filesSearchUseCase
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
    
    func search(by searchText: String) async throws -> [NodeEntity] {
        guard let parentNode else { return [] }
        return try await filesSearchUseCase.search(
            filter: .recursive(
                searchText: searchText,
                searchTargetLocation: .parentNode(parentNode.toNodeEntity()),
                supportCancel: true,
                sortOrderType: .defaultAsc,
                formatType: .unknown,
                sensitiveFilterOption: await sensitiveDisplayPreferenceUseCase.excludeSensitives() ? .nonSensitiveOnly : .disabled,
                favouriteFilterOption: .disabled,
                useAndForTextQuery: false
            ),
            cancelPreviousSearchIfNeeded: true
        )
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
