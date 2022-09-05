import MEGADomain

public struct MockCaptureDeviceUseCase: CaptureDeviceUseCaseProtocol {
    public var cameraPositionName: String?
    
    public init(cameraPositionName: String? = nil) {
        self.cameraPositionName = cameraPositionName
    }
    
    public func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String? {
        return cameraPositionName
    }
}
