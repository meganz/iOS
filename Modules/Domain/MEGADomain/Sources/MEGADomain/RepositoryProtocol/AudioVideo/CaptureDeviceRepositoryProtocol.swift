public protocol CaptureDeviceRepositoryProtocol: Sendable {
    func wideAngleCameraLocalizedName(position: CameraPositionEntity) -> String?
}
