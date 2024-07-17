import MEGADomain

public struct MockCameraUploadsRepository: CameraUploadsRepositoryProtocol {
    public static let newRepo: MockCameraUploadsRepository = MockCameraUploadsRepository()
    private let cameraUploadsNode: NodeEntity
    private let cameraUploadsNodeHandle: HandleEntity
    private let isCameraUploadsNode: Bool
    
    public init(cameraUploadsNode: NodeEntity = NodeEntity(name: "Camera Uploads"), cameraUploadsNodeHandle: HandleEntity = HandleEntity(1), isCameraUploadsNode: Bool = false) {
        self.cameraUploadsNode = cameraUploadsNode
        self.cameraUploadsNodeHandle = cameraUploadsNodeHandle
        self.isCameraUploadsNode = isCameraUploadsNode
    }
    
    public func cameraUploadsNode() async throws -> NodeEntity {
        cameraUploadsNode
    }
    
    public func registerCameraUploadsBackup(_ nodeName: String) async throws -> HandleEntity {
        cameraUploadsNodeHandle
    }
    
    public func unregisterCameraUploadsBackup(_ handle: HandleEntity) async throws {
    }
    
    public func updateCameraUploadsBackupName(_ handle: HandleEntity) async throws {
    }
    
    public func updateCameraUploadsBackupState(_ handle: HandleEntity, state: BackUpStateEntity, substate: BackUpSubStateEntity) async throws {
    }
    
    public func isCameraUploadsNode(handle: HandleEntity) async throws -> Bool {
        isCameraUploadsNode
    }
    
    public func registerCameraUploadNodeNameUpdate(callback: @escaping () -> Void) {
    }
    
    public func removeCameraUploadNodeNameUpdate() {
    }
}
