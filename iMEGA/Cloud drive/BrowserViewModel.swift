import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAFoundation

@MainActor
@objc public final class BrowserViewModel: NSObject, ViewModelType {
    public enum Action: ActionType {
        case onViewAppear
        case onViewDisappear
    }

    public enum Command: CommandType, Equatable {
        case nodesUpdate([NodeEntity])
        case copyRequestStartUpdate
        case requestFinishUpdates(RequestEntity)
    }
    
    public var invokeCommand: ((Command) -> Void)?
    public func dispatch(_ action: Action) {
        switch action {
        case .onViewAppear:
            onViewAppear()
        case .onViewDisappear:
            onViewDisappear()
        }
    }
    
    private let isChildBrowser: Bool
    private let isSelectVideos: Bool
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let filesSearchUseCase: any FilesSearchUseCaseProtocol
    private let sdk: MEGASdk
    private var parentNode: MEGANode?
    private var metadataUseCase: any MetadataUseCaseProtocol
    private let browserUseCase: any BrowserUseCaseProtocol
    
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
    
    var monitorNodeUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    var monitorCopyRequestStartUpdates: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    var monitorRequestFinishUpdates: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    init(parentNode: MEGANode?,
         isChildBrowser: Bool,
         isSelectVideos: Bool,
         sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
         filesSearchUseCase: some FilesSearchUseCaseProtocol,
         metadataUseCase: some MetadataUseCaseProtocol,
         sdk: MEGASdk = .shared,
         browserUseCase: some BrowserUseCaseProtocol) {
        self.parentNode = parentNode
        self.isChildBrowser = isChildBrowser
        self.isSelectVideos = isSelectVideos
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.filesSearchUseCase = filesSearchUseCase
        self.metadataUseCase = metadataUseCase
        self.sdk = sdk
        self.browserUseCase = browserUseCase
    }
    
    private func onViewAppear() {
        monitorNodeUpdatesTask = Task { [weak self, browserUseCase] in
            for await nodeEntities in browserUseCase.nodeUpdates {
                guard !Task.isCancelled else { break }
                self?.invokeCommand?(.nodesUpdate(nodeEntities))
            }
        }
        
        monitorCopyRequestStartUpdates = Task { [weak self, browserUseCase] in
            for await _ in browserUseCase.copyRequestStartUpdates {
                guard !Task.isCancelled else { break }
                self?.invokeCommand?(.copyRequestStartUpdate)
            }
        }
        
        monitorRequestFinishUpdates = Task { [weak self, browserUseCase] in
            for await requestEntity in browserUseCase.requestFinishUpdates {
                guard !Task.isCancelled else { break }
                self?.invokeCommand?(.requestFinishUpdates(requestEntity))
            }
        }
    }
    
    private func onViewDisappear() {
        monitorNodeUpdatesTask = nil
        monitorCopyRequestStartUpdates = nil
        monitorRequestFinishUpdates = nil
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
        let nodes: [NodeEntity] = try await filesSearchUseCase.search(
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
        
        return if isSelectVideos {
            nodes.filter { $0.isFolder || $0.name.fileExtensionGroup.isVideo }
        } else {
            nodes
        }
    }
    
    @objc func upload(localPath: String?, parentHandle: UInt64, presenter: UIViewController) async {
        guard let localPath else { return }
        let localFileURL = if let url = URL(string: localPath), url.isFileURL { url } else { URL(fileURLWithPath: localPath) }
        let appData: String? = await metadataUseCase.formattedCoordinate(forFilePath: localPath)
        let transfer = CancellableTransfer(
            handle: .invalid,
            parentHandle: parentHandle,
            fileLinkURL: nil,
            localFileURL: localFileURL,
            name: nil,
            appData: appData,
            priority: false,
            isFile: true,
            type: .upload
        )
        
        let collisionEntity = NameCollisionEntity(
            parentHandle: transfer.parentHandle,
            name: transfer.localFileURL?.lastPathComponent ?? "",
            isFile: transfer.isFile,
            fileUrl: transfer.localFileURL
        )
        
        NameCollisionViewRouter(
            presenter: presenter,
            transfers: [transfer],
            nodes: nil,
            collisions: [collisionEntity],
            collisionType: .upload
        ).start()
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
