import Foundation

typealias NodeLoadCompletion = (_ node: MEGANode?, _ error: Error?) -> Void

struct NodeAccessConfiguration {
    var autoCreate: (() -> Bool)? = nil
    let updateInMemoryNotificationName: Notification.Name
    let updateInRemoteNotificationName: Notification.Name
    let loadNodeRequest: (MEGARequestDelegate) -> Void
    var setNodeRequest: ((MEGAHandle, MEGARequestDelegate) -> Void)? = nil
    var nodeName: String? = nil
    var createNodeRequest: ((String, MEGANode, MEGARequestDelegate) -> Void)? = nil
}

class NodeAccess: NSObject {
    let sdk = MEGASdkManager.sharedMEGASdk()
    private let nodeAccessSemaphore = DispatchSemaphore(value: 1)
    private var nodeAccessConfiguration: NodeAccessConfiguration
    private var nodeLoadOperation: NodeLoadOperation?
    
    /// All changes in the SDK and in memory are notified so that the handle value is always up to date. This handle is the single source of truth on target node handle check.
    private var handle: NodeHandle? {
        didSet {
            if handle != oldValue && oldValue != nil {
                NotificationCenter.default.post(name: nodeAccessConfiguration.updateInMemoryNotificationName, object: nil)
            }
        }
    }
    
    init(configuration: NodeAccessConfiguration) {
        self.nodeAccessConfiguration = configuration
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNodeChangeNotification), name: nodeAccessConfiguration.updateInRemoteNotificationName, object: nil)
        
        loadNodeToMemory()
    }
    
    /// Check if a given node is the target folder or not
    ///
    /// - Attention:
    /// This method is not as accurate as `loadNode(:)` which will check if the current target node in memory is valid or not, and load it from server side if needed.
    /// This method `isTargetNode` simply check if the given node against the current target node in memory. There is a small gap that the target node
    /// in memory is not valid in some edge cases. If you need accurate target node, please use `loadNode(:)` method.
    ///
    /// - Parameter node: The given node to be checked
    /// - Returns: if the node is the target folder return true, otherwise return false
    @objc func isTargetNode(for node: MEGANode) -> Bool { handle != nil && node.handle == handle }
    
    /// Load the current type node, it follows the below steps to load the node:
    /// 1. If the handle in memory is valid, we return it
    /// 2. Otherwise, we try to load the node from server side
    /// 3. If the current type node is nonexist in server side, we create a new one and return it
    ///
    /// - Attention:
    /// Here we are using the double-checked locking approach to boost the performance. If the handle in memory is valid,
    /// we will return it straghtaway without going through the synchronisation point. Double-checked locking anti-pattern
    /// is not a concern here, as handle is a primitive type and it is safe to enter the synchronisation point.
    ///
    /// - Parameter completion: A block that the node loader calls after the node load completes. It will be called on an arbitrary dispatch queue. Please dispatch to Main queue if need to update UI.
    @objc func loadNode(completion: NodeLoadCompletion? = nil) {
        guard let node = handle?.validNode(in: sdk) else {
            DispatchQueue.global(qos: .userInitiated).async {
                self.loadNodeWithSynchronisation(completion: completion)
            }
            return
        }
        
        completion?(node, nil)
    }
    
    private func loadNodeWithSynchronisation(completion: NodeLoadCompletion? = nil) {
        nodeAccessSemaphore.wait()
        
        guard let node = handle?.validNode(in: sdk) else {
            let operation = NodeLoadOperation(autoCreate:nodeAccessConfiguration.autoCreate,
                                              loadNodeRequest: nodeAccessConfiguration.loadNodeRequest,
                                              newNodeName: nodeAccessConfiguration.nodeName,
                                              createNodeRequest: nodeAccessConfiguration.createNodeRequest,
                                              setFolderHandleRequest: nodeAccessConfiguration.setNodeRequest) { [weak self] node, error in
                self?.updateHandle(node, error: error, completion: completion)
            }
        
            operation.start()
            nodeLoadOperation = operation
            return
        }
        
        completion?(node, nil)
        nodeAccessSemaphore.signal()
    }
    
    private func updateHandle(_ node: MEGANode?, error: Error?, completion: NodeLoadCompletion?) {
        self.handle = node?.handle
        completion?(node, error)

        self.nodeAccessSemaphore.signal()
    }
    
    private func loadNodeToMemory() {
        loadNode { _, error in
            MEGALogWarning("NodeAccess. could not load node to memory \(String(describing: error))")
        }
    }
    
    // MARK: - Switch node
    
    /// Set a new node as the target folder node
    /// - Parameters:
    ///   - node: The given node to be set to be Camera Uploads target folder node
    ///   - completion: A callback closure when set node completes. It will be called on an arbitrary dispatch queue. Please dispatch to Main queue if need to update UI.
    @objc func setNode(_ node: MEGANode, completion: NodeLoadCompletion? = nil) {
        guard node.handle != handle, let setNodeRequest = nodeAccessConfiguration.setNodeRequest else {
            completion?(node, nil)
            return
        }
    
        nodeAccessSemaphore.wait()
        
        setNodeRequest(node.handle, RequestDelegate { [weak self] result in
            switch result {
            case .success:
                self?.handle = node.handle
                completion?(node, nil)
            case .failure(let error):
                completion?(nil, error)
            }
            
            self?.nodeAccessSemaphore.signal()
        })
    }
    
    @objc func didReceiveNodeChangeNotification() {
        handle = nil
        
        loadNodeToMemory()
    }
}
