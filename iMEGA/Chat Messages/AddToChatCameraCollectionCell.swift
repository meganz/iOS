
import UIKit

class AddToChatCameraCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var liveFeedView: UIView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    enum LiveFeedError: Error {
        case askForPermission
        case captureDeviceInstantiationFailed
        case captureDeviceInputInstantiationFailed
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func showLiveFeed() throws {
        if DevicePermissionsHelper.shouldAskForVideoPermissions() {
            throw LiveFeedError.askForPermission
        }
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = liveFeedView.layer.bounds
    }

}
