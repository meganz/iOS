import UIKit

class StorageFullModalAlertViewController: CustomModalAlertViewController {
    
    
    private let limitedSpace = 100 * 1024 * 1024
    private let duration = 2
    
    private var requiredStorage: Int64 = 100 * 1024 * 1024
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "CustomModalAlertViewController", bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        configureView()
        super.viewDidLoad()
    }
    
    func configureView() {
        image = UIImage(named: "deviceStorageAlmostFull")
        viewTitle = NSLocalizedString("Device Storage Almost Full", comment: "Title to show when device local storage is almost full")
        detail = String(format: NSLocalizedString("MEGA needs a minimum of %@. Free up some space by deleting apps you no longer use or large video files in your gallery. You can also manage what MEGA stores on your device.", comment: "Message shown when you try to downlonad files bigger than the available memory."), Helper.memoryStyleString(fromByteCount: requiredStorage)
)
        firstButtonTitle = NSLocalizedString("Manage", comment: "Text indicating to the user some action should be addressed. E.g. Navigate to Settings/File Management to clear cache.")
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                let fileManagementVC = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "FileManagementTableViewControllerID")
                UIApplication.mnz_visibleViewController().navigationController?.pushViewController(fileManagementVC, animated: true)
            })
        }
        
        dismissButtonTitle = NSLocalizedString("notNow", comment: "Text indicating to the user that some action will be postpone. E.g. used for 'rich previews' and management of disk storage.")
        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "MEGAStorageFullNotification")
            })
        }
    }
    
    @objc func show() {
        show(requiredStorage: requiredStorage)
    }
    
    @objc func show(requiredStorage: Int64) {
        modalPresentationStyle = .overFullScreen;
        self.requiredStorage = requiredStorage
        UIApplication.mnz_visibleViewController().present(self, animated: true, completion: nil)
    }
    
    @objc func showStorageAlertIfNeeded() {
        let storageDate = Date(timeIntervalSince1970: TimeInterval(UserDefaults.standard.double(forKey: "MEGAStorageFullNotification"))) as NSDate
        
        guard FileManager.default.mnz_fileSystemFreeSize < limitedSpace,
            storageDate.daysEarlierThan(Date()) < duration else {
            return
        }
        
        show()
    }
}
