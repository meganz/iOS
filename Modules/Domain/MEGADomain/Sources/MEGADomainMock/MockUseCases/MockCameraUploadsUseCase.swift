import MEGADomain

public struct MockCameraUploadsUseCase: CameraUploadsUseCaseProtocol {
    private let cuNode: NodeEntity
    private let isCameraUploadsNode: Bool
    
    public init(cuNode: NodeEntity, isCameraUploadsNode: Bool) {
        self.cuNode = cuNode
        self.isCameraUploadsNode = isCameraUploadsNode
    }
    
    public func cameraUploadsNode() async throws -> NodeEntity {
        cuNode
    }
    
    public func registerCameraUploadsBackup(_ nodeName: String) async throws -> HandleEntity {
        cuNode.handle
    }
    
    public func unregisterCameraUploadsBackup(_ handle: HandleEntity) async throws {}
    
    public func updateCameraUploadsBackupName(_ handle: HandleEntity) async throws {}
    
    public func updateCameraUploadsBackupState(_ handle: HandleEntity, state: BackUpStateEntity, substate: BackUpSubStateEntity) async throws {}
    
    public func isCameraUploadsNode(handle: HandleEntity) async throws -> Bool {
        isCameraUploadsNode
    }
    
    public func registerCameraUploadNodeNameUpdate(callback: @escaping () -> Void) {
        callback()
    }
    
    public func removeCameraUploadNodeNameUpdate() {}
}
