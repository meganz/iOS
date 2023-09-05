import AVFoundation
import MEGADomain

public struct CaptureDeviceRepository: CaptureDeviceRepositoryProtocol {
    public init() {}

    public func wideAngleCameraLocalizedName(position: CameraPositionEntity) -> String? {
        guard let capturePosition = AVCaptureDevice.Position(rawValue: position.toCameraPositionCode()) else {
            return nil
        }
        
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: capturePosition)?.localizedName
    }
}
