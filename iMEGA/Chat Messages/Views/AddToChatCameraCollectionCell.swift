
import UIKit

class AddToChatCameraCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var liveFeedView: UIView!
    @IBOutlet weak var cameraIconImageView: UIImageView!

    var previewLayer: AVCaptureVideoPreviewLayer!
    var isCurrentShowingLiveFeed = false
    
    enum LiveFeedError: Error {
        case askForPermission
        case captureDeviceInstantiationFailed
        case captureDeviceInputInstantiationFailed
    }
    
    func showLiveFeed() throws {
        if DevicePermissionsHelper.shouldAskForVideoPermissions() {
            cameraIconImageView.image = #imageLiteral(resourceName: "cameraIcon")
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
        cameraIconImageView.image = #imageLiteral(resourceName: "cameraIconWhite")
    }
    
    func hideLiveFeedView() {
        liveFeedView.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        addCornerRadius()
        guard let previewLayer = previewLayer else {
            return
        }
        
        previewLayer.frame = liveFeedView.layer.bounds
    }
    
    private func addCornerRadius() {
        layer.cornerRadius = 4.0
        
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: [.topLeft],
                                    cornerRadii: CGSize(width: 8.0, height: 0.0))

        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }

}
