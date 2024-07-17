import Foundation

public protocol CameraUploadsRepositoryProtocol: RepositoryProtocol, Sendable {
    func cameraUploadsNode() async throws -> NodeEntity
    func registerCameraUploadsBackup(_ nodeName: String) async throws -> HandleEntity
    func unregisterCameraUploadsBackup(_ handle: HandleEntity) async throws
    func updateCameraUploadsBackupName(_ handle: HandleEntity) async throws
    func updateCameraUploadsBackupState(_ handle: HandleEntity, state: BackUpStateEntity, substate: BackUpSubStateEntity) async throws
    func isCameraUploadsNode(handle: HandleEntity) async throws -> Bool
    func registerCameraUploadNodeNameUpdate(callback: @escaping @Sendable () -> Void)
    func removeCameraUploadNodeNameUpdate()
}
