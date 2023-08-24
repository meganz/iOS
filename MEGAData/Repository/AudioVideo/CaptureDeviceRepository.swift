import MEGADomain

struct CaptureDeviceRepository: CaptureDeviceRepositoryProtocol {
    
    func wideAngleCameraLocalizedName(position: CameraPositionEntity) -> String? {
        guard let capturePosition = AVCaptureDevice.Position(rawValue: position.toCameraPositionCode()) else {
            return nil
        }
        
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: capturePosition)?.localizedName
    }
    
}
