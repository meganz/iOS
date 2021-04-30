

struct CaptureDeviceRepository: CaptureDeviceRepositoryProtocol {
    
    func wideAngleCameraLocalizedName(postion: CameraPosition) -> String? {
        guard let capturePosition = AVCaptureDevice.Position(rawValue: postion.rawValue) else {
            return nil
        }
        
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: capturePosition)?.localizedName
    }
    
}
