import UIKit

class ImportTextActivity: UIActivity, BrowserViewControllerDelegate {
    
    var content: String

    @objc init(content: String) {
        self.content = content
        super.init()
    }

    override var activityTitle: String? {
        return Strings.Localizable.importToCloudDrive
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "import")
    }
    
    override func perform() {
        let storyboard = UIStoryboard(name: "Cloud", bundle: Bundle(for: BrowserViewController.self))
        if let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserViewControllerID") as? BrowserViewController {

            browserVC.browserViewControllerDelegate = self
            browserVC.browserAction = .newHomeUpload
            let browserNavigationController = MEGANavigationController(rootViewController: browserVC)
            browserNavigationController.setToolbarHidden(false, animated: false)
            UIApplication.mnz_presentingViewController().present(browserNavigationController, animated: true, completion: nil)
        }
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override class var activityCategory: UIActivity.Category {
        return .action
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType(rawValue: MEGAUIActivityTypeImportToCloudDrive)
    }
    
    func upload(toParentNode parentNode: MEGANode) {
        let fileName = "Chat \(NSDate().mnz_formattedDefaultNameForMedia()).txt"
        let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)

        do {
            try content.write(toFile: tempPath, atomically: true, encoding: .utf8)
            MEGASdkManager.sharedMEGASdk().startUpload(withLocalPath: tempPath, parent: parentNode, appData: "", isSourceTemporary: true)
        } catch {
            MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
        }
        self.activityDidFinish(true)
        UIApplication.mnz_presentingViewController().dismiss(animated: true)
    }
}
