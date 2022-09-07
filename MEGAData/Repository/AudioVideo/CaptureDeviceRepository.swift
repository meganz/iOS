import MEGADomain

struct CaptureDeviceRepository: CaptureDeviceRepositoryProtocol {
    
    func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String? {
        guard let capturePosition = AVCaptureDevice.Position(rawValue: postion.toCameraPositionCode()) else {
            return nil
        }
        
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: capturePosition)?.localizedName
    }
    
}
