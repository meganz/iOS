@testable import MEGA

struct MockCaptureDeviceUseCase: CaptureDeviceUseCaseProtocol {
    var cameraPositionName: String?
    
    func wideAngleCameraLocalizedName(postion: CameraPosition) -> String? {
        return cameraPositionName
    }
}

