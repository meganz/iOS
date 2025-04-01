import MEGAAppPresentation
import UIKit

typealias CameraUploadEnabledStateDidChange = () -> Void

struct CameraUploadsSettingsViewRouter: Routing {
    private weak var presenter: UINavigationController?
    private var cameraUploadSettingChanged: CameraUploadEnabledStateDidChange
    
    init(presenter: UINavigationController?, closure: @escaping CameraUploadEnabledStateDidChange) {
        self.presenter = presenter
        self.cameraUploadSettingChanged = closure
    }
    
    func build() -> UIViewController {
        let storyboard = UIStoryboard(name: "CameraUploadSettings", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CameraUploadsSettingsID") as! CameraUploadsTableViewController
        vc.cameraUploadSettingChanged = cameraUploadSettingChanged
        return vc
    }
    
    func start() {
        let viewController = build()
        presenter?.pushViewController(viewController, animated: true)
    }
}
