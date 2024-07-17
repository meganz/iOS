public protocol CameraUploadsUseCaseProtocol: Sendable {
    func cameraUploadsNode() async throws -> NodeEntity
    func registerCameraUploadsBackup(_ nodeName: String) async throws -> HandleEntity
    func unregisterCameraUploadsBackup(_ handle: HandleEntity) async throws
    func updateCameraUploadsBackupName(_ handle: HandleEntity) async throws
    func updateCameraUploadsBackupState(_ handle: HandleEntity, state: BackUpStateEntity, substate: BackUpSubStateEntity) async throws
    func isCameraUploadsNode(handle: HandleEntity) async throws -> Bool
    func registerCameraUploadNodeNameUpdate(callback: @escaping @Sendable () -> Void)
    func removeCameraUploadNodeNameUpdate()
}

public struct CameraUploadsUseCase<T: CameraUploadsRepositoryProtocol>: CameraUploadsUseCaseProtocol {
    private let repo: T
    
    public init(cameraUploadsRepository: T) {
        self.repo = cameraUploadsRepository
    }
    
    public func cameraUploadsNode() async throws -> NodeEntity {
        try await repo.cameraUploadsNode()
    }
    
    public func registerCameraUploadsBackup(_ nodeName: String) async throws -> HandleEntity {
        try await repo.registerCameraUploadsBackup(nodeName)
    }
    
    public func unregisterCameraUploadsBackup(_ handle: HandleEntity) async throws {
        try await repo.unregisterCameraUploadsBackup(handle)
    }
    
    public func updateCameraUploadsBackupName(_ handle: HandleEntity) async throws {
        try await repo.updateCameraUploadsBackupName(handle)
    }
    
    public func updateCameraUploadsBackupState(_ handle: HandleEntity, state: BackUpStateEntity, substate: BackUpSubStateEntity) async throws {
        try await repo.updateCameraUploadsBackupState(handle, state: state, substate: substate)
    }
    
    public func isCameraUploadsNode(handle: HandleEntity) async throws -> Bool {
        try await repo.isCameraUploadsNode(handle: handle)
    }
    
    public func registerCameraUploadNodeNameUpdate(callback: @escaping @Sendable () -> Void) {
        repo.registerCameraUploadNodeNameUpdate(callback: callback)
    }
    
    public func removeCameraUploadNodeNameUpdate() {
        repo.removeCameraUploadNodeNameUpdate()
    }
}
