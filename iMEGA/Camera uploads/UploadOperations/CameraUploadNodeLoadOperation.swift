import Foundation

enum NodeLoadError: Error {
    case noRootNode
    case loadCancelled
    case invalidNode
}

final class CameraUploadNodeLoadOperation: MEGAOperation {
    // MARK: - Private properties
    private let completion: NodeLoadCompletion
    private let sdk: MEGASdk
    private let localCachedHandleKey = "CameraUploadsNodeHandle"
    private let autoCreate: Bool
    
    // MARK: - Init
    init(autoCreate: Bool, completion: @escaping NodeLoadCompletion) {
        self.autoCreate = autoCreate
        self.completion = completion
        sdk = MEGASdkManager.sharedMEGASdk()
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
    
    private func finishOperation(node: MEGANode?, error: Error?) {
        completion(node, error)
        finish()
    }
    
    // MARK: - Load from remote
    private func loadNodeFromRemote() {
        sdk.getCameraUploadsFolder(with: MEGAGenericRequestDelegate { [weak self] request, error in
            switch error.type {
            case .apiOk:
                self?.validateLoadedHandle(request.nodeHandle)
            case .apiENoent:
                self?.checkLocalCacheForBackwardsCompatibility()
            default:
                self?.finishOperation(node: nil, error: error)
            }
        })
    }
    
    // MARK: - Check loaded node handle
    private func validateLoadedHandle(_ handle: NodeHandle) {
        guard let node = handle.validNode(in: sdk) else {
            if autoCreate {
                createCameraUploadNode()
            } else {
                finishOperation(node: nil, error: NodeLoadError.invalidNode)
            }
            return
        }
        
        finishOperation(node: node, error: nil)
    }
    
    // MARK: - Backwards compatibility for local cache
    private func checkLocalCacheForBackwardsCompatibility() {
        guard autoCreate else {
            finishOperation(node: nil, error: NodeLoadError.invalidNode)
            return
        }
        
        guard let cachedHandleNumber = UserDefaults.standard.object(forKey: localCachedHandleKey) as? NSNumber else {
            createCameraUploadNode()
            return
        }
        
        guard let node = cachedHandleNumber.uint64Value.validNode(in: sdk) else {
            createCameraUploadNode()
            return
        }
        
        setCameraUploadTargetFolder(forHandle: node.handle)
    }
    
    private func clearLocalCache() {
        UserDefaults.standard.removeObject(forKey: localCachedHandleKey)
    }
    
    // MARK: - Create Camera Upload Node
    private func createCameraUploadNode() {
        guard let parent = sdk.rootNode else {
            finishOperation(node: nil, error: NodeLoadError.noRootNode)
            return
        }
        
        let name = AMLocalizedString("cameraUploadsLabel", "Name of the auto-generated Camera Upload folder")
        sdk.createFolder(withName: name, parent: parent, delegate: MEGAGenericRequestDelegate { [weak self] request, error in
            switch error.type {
            case .apiOk:
                self?.setCameraUploadTargetFolder(forHandle: request.nodeHandle)
            default:
                self?.finishOperation(node: nil, error: error)
            }
        })
    }
    
    // MARK: - Set a node handle to be the target folder
    private func setCameraUploadTargetFolder(forHandle handle: NodeHandle) {
        sdk.setCameraUploadsFolderWithHandle(handle, delegate: MEGAGenericRequestDelegate { [weak self] request, error in
            switch error.type {
            case .apiOk:
                self?.validateLoadedHandle(handle)
                self?.clearLocalCache()
            default:
                self?.finishOperation(node: nil, error: error)
            }
        })
    }
}
