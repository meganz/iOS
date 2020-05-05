
import UIKit

class AddToChatCameraCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var liveFeedView: UIView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var isCurrentShowingLiveFeed = false
    
    enum LiveFeedError: Error {
        case askForPermission
        case captureDeviceInstantiationFailed
        case captureDeviceInputInstantiationFailed
    }
    
    func showLiveFeed() throws {
        if DevicePermissionsHelper.shouldAskForVideoPermissions() {
            throw LiveFeedError.askForPermission
        }
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        liveFeedView.isHidden = false
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        liveFeedView.layer.addSublayer(previewLayer)
       
        let deviceDiscoverySession = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                             for: AVMediaType.video,
                                                             position: .back)
        
        guard let captureDevice = deviceDiscoverySession else {
            throw LiveFeedError.captureDeviceInstantiationFailed
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            throw LiveFeedError.captureDeviceInputInstantiationFailed
        }
        
        captureSession.startRunning()
        liveFeedView.isHidden = false
        isCurrentShowingLiveFeed = true
    }
    
    func hideLiveFeedView() {
        liveFeedView.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let previewLayer = previewLayer else {
            return
        }
        
        previewLayer.frame = liveFeedView.layer.bounds
    }

}
