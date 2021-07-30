@testable import MEGA

struct MockCaptureDeviceUseCase: CaptureDeviceUseCaseProtocol {
    var cameraPositionName: String?
    
    func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String? {
        return cameraPositionName
    }
}

