import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

public final class CameraUploadsRepository: NSObject, CameraUploadsRepositoryProtocol {
    actor TaskManager {
        private var cameraUploadNodeNameUpdateCompletion: (@Sendable () -> Void)?
        
        func register(cameraUploadNodeNameUpdateCompletion: @escaping @Sendable () -> Void) {
            self.cameraUploadNodeNameUpdateCompletion = cameraUploadNodeNameUpdateCompletion
        }
        
        func removeCameraUploadNodeNameUpdateCompletion() {
            cameraUploadNodeNameUpdateCompletion = nil
        }
        
        func executeCameraUploadNodeNameUpdateCompletion() {
            cameraUploadNodeNameUpdateCompletion?()
        }
    }
    
    public static var newRepo: CameraUploadsRepository {
        CameraUploadsRepository(
            sdk: MEGASdk.sharedSdk,
            cameraUploadsNodeAccess: CameraUploadNodeAccess.shared
        )
    }

    private let sdk: MEGASdk
    private let taskManager = TaskManager()
    private let cameraUploadsNodeAccess: CameraUploadNodeAccess

    public init(sdk: MEGASdk, cameraUploadsNodeAccess: CameraUploadNodeAccess) {
        self.sdk = sdk
        self.cameraUploadsNodeAccess = cameraUploadsNodeAccess
    }
    
    private func handleSdkResult<T, E: Error>(
        _ result: Result<T, E>,
        with completion: @escaping (Result<T, any Error>) -> Void
    ) {
        switch result {
        case .failure(let error):
            completion(.failure(error))
        case .success(let value):
            completion(.success(value))
        }
    }

    public func cameraUploadsNode() async throws -> NodeEntity {
        try await withAsyncThrowingValue(in: { completion in
            cameraUploadsNodeAccess.loadNode { node, _ in
                guard let node = node else {
                    completion(.failure(FolderInfoErrorEntity.notFound))
                    return
                }
                
                completion(.success(node.toNodeEntity()))
            }
        })
    }
    
    public func registerCameraUploadsBackup(_ nodeName: String) async throws -> HandleEntity {
        let cameraUploadsNodeEntity = try await cameraUploadsNode()
        
        guard let cuNode = cameraUploadsNodeEntity.toMEGANode(in: sdk) else {
            throw NodeErrorEntity.nodeNotFound
        }
        
        return try await withAsyncThrowingValue { completion in
            sdk.registerBackup(
                .cameraUploads,
                targetNode: cuNode,
                folderPath: MEGACameraUploadsFolderPath,
                name: nodeName,
                state: .active,
                delegate: RequestDelegate { [weak self] result in
                    self?.handleSdkResult(result.map { $0.parentHandle }, with: completion)
            })
        }
    }
    
    public func unregisterCameraUploadsBackup(_ handle: HandleEntity) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.unregisterBackup(handle, delegate: RequestDelegate { [weak self] result in
                self?.handleSdkResult(result.map { _ in () }, with: completion)
            })
        }
    }

    public func updateCameraUploadsBackupName(_ handle: HandleEntity) async throws {
        let cuNodeEntity = try await cameraUploadsNode()
        
        guard let cuNode = cuNodeEntity.toMEGANode(in: sdk),
              let cuNodeName = cuNode.name else {
            throw BackupNodeErrorEntity.notFound
        }
        
        try await withAsyncThrowingValue { completion in
            sdk.updateBackup(handle,
                             backupType: .cameraUploads,
                             targetNode: cuNode,
                             folderPath: nil,
                             backupName: cuNodeName,
                             state: .invalid,
                             subState: .invalid,
                             delegate: RequestDelegate { [weak self] result in
                                self?.handleSdkResult(result.map { _ in () }, with: completion)
                             })
        }
    }

    public func updateCameraUploadsBackupState(_ handle: HandleEntity, state: BackUpStateEntity, substate: BackUpSubStateEntity) async throws {
        let cuNodeEntity = try await cameraUploadsNode()
        
        guard let cuNode = cuNodeEntity.toMEGANode(in: sdk) else {
            throw BackupNodeErrorEntity.notFound
        }
        
        try await withAsyncThrowingValue { completion in
            sdk.updateBackup(handle,
                             backupType: .cameraUploads,
                             targetNode: cuNode,
                             folderPath: nil,
                             backupName: nil,
                             state: state.toBackUpState(),
                             subState: substate.toBackUpSubState(),
                             delegate: RequestDelegate { [weak self] result in
                                self?.handleSdkResult(result.map { _ in () }, with: completion)
                             })
        }
    }

    public func isCameraUploadsNode(handle: HandleEntity) async throws -> Bool {
        let cuNodeEntity = try await cameraUploadsNode()
        return cuNodeEntity.handle == handle
    }
    
    public func registerCameraUploadNodeNameUpdate(callback: @escaping @Sendable () -> Void) {
        Task {
            sdk.add(self)
            await taskManager.register(cameraUploadNodeNameUpdateCompletion: callback)
        }
    }
    
    public func removeCameraUploadNodeNameUpdate() {
        Task {
            sdk.remove(self)
            await taskManager.removeCameraUploadNodeNameUpdateCompletion()
        }
    }
}

extension CameraUploadsRepository: MEGAGlobalDelegate {
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        Task {
            guard let nodes = nodeList?.toNodeArray() else { return }
            let renamedNodes = nodes.nodes(for: [.name])
             
            guard let cameraUploadsNode = try? await cameraUploadsNode() else { return }
           
            let isCUNodeRenamed = renamedNodes.contains(where: { node in
                node.handle == cameraUploadsNode.handle
            })
            
            if isCUNodeRenamed {
                await taskManager.executeCameraUploadNodeNameUpdateCompletion()
            }
        }
    }
}
