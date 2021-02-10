import Foundation

typealias NodeLoadCompletion = (_ node: MEGANode?, _ error: Error?) -> Void

final class CameraUploadNodeAccess: NSObject {
    // MARK: - Private properties
    private let sdk: MEGASdk = MEGASdkManager.sharedMEGASdk()
    private let nodeAccessSemaphore = DispatchSemaphore(value: 1)
    private var handle: NodeHandle? {
        didSet {
            if handle != oldValue && oldValue != nil {
                NotificationCenter.default.post(name: NSNotification.Name.MEGACameraUploadTargetFolderUpdatedInMemory, object: nil)
            }
        }
    }
    private var nodeLoadOperation: CameraUploadNodeLoadOperation?
    
    @objc static let shared = CameraUploadNodeAccess()
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNodeChangeNotification), name: NSNotification.Name.MEGACameraUploadTargetFolderChangedInRemote, object: nil)
        loadNodeToMemory()
    }
    
    /// Check if a given node is Camera Uploads target folder or not
    ///
    /// - Attention:
    /// This method is not as accurate as `loadNode(:)` which will check if the current target node in memory is valid or not, and load it from server side if needed.
    /// This method `isTargetNode` simply check if the given node against the current target node in memory. There is a small gap that the target node
    /// in memory is not valid in some edge cases. If you need accurate target node, please use `loadNode(:)` method.
    ///
    /// - Parameter node: The given node to be checked
    /// - Returns: if the node is the target folder return true, otherwise return false
    @objc func isTargetNode(for node: MEGANode) -> Bool { node.handle == handle }
    
    // MARK: - Load node
    
    /// Load Camera Upload node, it follows the below steps to load the node:
    /// 1. If the handle in memory is valid, we return it
    /// 2. Otherwise, we try to load the node from server side
    /// 3. If the CU node is nonexist in server side, we create a new one and return it
    ///
    /// - Attention:
    /// Here we are using the double-checked locking approach to boost the performance. If the handle in memory is valid,
    /// we will return it straghtaway without going through the synchronisation point. Double-checked locking anti-pattern
    /// is not a concern here, as handle is a primitive type and it is safe to enter the synchronisation point.
    ///
    /// - Parameter completion: A block that the node loader calls after the node load completes. It will be called on an arbitrary dispatch queue. Please dispatch to Main queue if need to update UI.
    @objc func loadNode(completion: @escaping NodeLoadCompletion) {
        guard let node = handle?.validNode(in: sdk) else {
            DispatchQueue.global(qos: .userInitiated).async {
                self.loadNodeWithSynchronisation(completion: completion)
            }
            return
        }
        
        completion(node, nil)
    }
    
    private func loadNodeWithSynchronisation(completion: @escaping NodeLoadCompletion) {
        MEGALogDebug("[Camera Upload] thead \(Thread.current) wait to load target folder")
        nodeAccessSemaphore.wait()
        MEGALogDebug("[Camera Upload] thead \(Thread.current) starts loading target folder")
        
        guard let node = handle?.validNode(in: sdk) else {
            let operation = CameraUploadNodeLoadOperation(autoCreate: CameraUploadManager.isCameraUploadEnabled) { node, error in
                self.handle = node?.handle
                completion(node, error)
                MEGALogDebug("[Camera Upload] thead \(Thread.current) finished loading target folder")
                self.nodeAccessSemaphore.signal()
            }
            operation.start()
            nodeLoadOperation = operation
            return
        }
        
        completion(node, nil)
        MEGALogDebug("[Camera Upload] thead \(Thread.current) gets a valid target folder without loading")
        nodeAccessSemaphore.signal()
    }
    
    private func loadNodeToMemory() {
        loadNode { _, error in
            MEGALogWarning("[Camera Upload] could not load node to memory \(String(describing: error))")
        }
    }
    
    // MARK: - Switch node
    
    /// Set a new node as the Camera Uploads target folder node
    /// - Parameters:
    ///   - node: The given node to be set to be Camera Uploads target folder node
    ///   - completion: A callback closure when set node completes. It will be called on an arbitrary dispatch queue. Please dispatch to Main queue if need to update UI.
    @objc func setNode(_ node: MEGANode, completion: NodeLoadCompletion? = nil) {
        guard node.handle != handle else {
            completion?(node, nil)
            return
        }
        
        nodeAccessSemaphore.wait()
        
        sdk.setCameraUploadsFolderWithHandle(node.handle, delegate: RequestDelegate { result in
            switch result {
            case .success:
                self.handle = node.handle
                completion?(node, nil)
            case .failure(let error):
                completion?(nil, error)
            }
            
            self.nodeAccessSemaphore.signal()
        })
    }
    
    @objc func didReceiveNodeChangeNotification() {
        handle = nil
        
        loadNodeToMemory()
    }
}
