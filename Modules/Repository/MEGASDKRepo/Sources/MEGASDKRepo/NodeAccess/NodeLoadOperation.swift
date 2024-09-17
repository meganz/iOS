import Foundation
import MEGADomain
import MEGAFoundation
import MEGASdk

enum NodeLoadError: Error {
    case noRootNode
    case loadCancelled
    case invalidNode
    case autoCreateIsNotEnabled
}

final class NodeLoadOperation: AsyncOperation, NodeLoadOperationProtocol, @unchecked Sendable {
    // MARK: - Private properties
    private let loadNodeRequest: (any MEGARequestDelegate) -> Void
    private let newNodeName: String?
    private let createNodeRequest: ((String, MEGANode, any MEGARequestDelegate) -> Void)?
    private let setFolderHandleRequest: ((HandleEntity, any MEGARequestDelegate) -> Void)?
    private let completion: NodeLoadCompletion
    private let sdk: MEGASdk
    private let autoCreate: (() -> Bool)?
    
    // MARK: - Init
    init(autoCreate: (() -> Bool)?,
         sdk: MEGASdk = .sharedSdk,
         loadNodeRequest: @escaping (any MEGARequestDelegate) -> Void,
         newNodeName: String? = nil,
         createNodeRequest: ((String, MEGANode, any MEGARequestDelegate) -> Void)? = nil,
         setFolderHandleRequest: ((HandleEntity, any MEGARequestDelegate) -> Void)? = nil,
         completion: @escaping NodeLoadCompletion) {
        self.autoCreate = autoCreate
        self.sdk = sdk
        self.loadNodeRequest = loadNodeRequest
        self.newNodeName = newNodeName
        self.createNodeRequest = createNodeRequest
        self.setFolderHandleRequest = setFolderHandleRequest
        self.completion = completion
        super.init()
    }
    
    // MARK: - Life cycle
    override func start() {
        guard !isCancelled else {
            finishOperation(node: nil, error: NodeLoadError.loadCancelled)
            return
        }
        
        startExecuting()
        loadNodeFromRemote()
    }
    
    func finishOperation(node: MEGANode?, error: (any Error)?) {
        completion(node, error)
        finishOperation()
    }
    
    // MARK: - Load from remote
    func loadNodeFromRemote() {
        loadNodeRequest(RequestDelegate(completion: validate))
    }
    
    // MARK: - Check loaded node handle
    func validateLoadedHandle(_ handle: HandleEntity) {
        guard let node = handle.validNode(in: sdk) else {
            createNode()
            return
        }
        finishOperation(node: node, error: nil)
    }
    
    func createNode() {
        guard autoCreate?() == true else {
            finishOperation(node: nil, error: NodeLoadError.autoCreateIsNotEnabled)
            return
        }
        
        guard let parent = sdk.rootNode, let newNodeName = newNodeName else {
            finishOperation(node: nil, error: NodeLoadError.noRootNode)
            return
        }
        
        createNodeRequest?(newNodeName, parent, RequestDelegate { [weak self] result in
            switch result {
            case .success(let request):
                self?.setTargetFolder(forHandle: request.nodeHandle)
            case .failure(let error):
                self?.finishOperation(node: nil, error: error)
            }
        })
    }
    
    func setTargetFolder(forHandle handle: HandleEntity) {
        setFolderHandleRequest?(handle, RequestDelegate(completion: validate))
    }
    
    private func validate(result: Result<MEGARequest, MEGAError>) {
        switch result {
        case .success(let request):
            validateLoadedHandle(request.nodeHandle)
        case .failure(let error):
            if error.type == .apiENoent {
                createNode()
            } else {
                finishOperation(node: nil, error: error)
            }
        }
    }
}
