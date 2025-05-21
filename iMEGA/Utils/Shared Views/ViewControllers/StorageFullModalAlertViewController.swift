import MEGAAssets
import MEGAFoundation
import MEGAL10n
import MEGASwift
import UIKit

class StorageFullModalAlertViewController: CustomModalAlertViewController {
    var storageViewModel: StorageFullModalAlertViewModel?

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
        image = MEGAAssets.UIImage.deviceStorageAlmostFull
        viewTitle = Strings.Localizable.deviceStorageAlmostFull
        detail = Strings.Localizable.MEGANeedsAMinimumOf
            .FreeUpSomeSpaceByDeletingAppsYouNoLongerUseOrLargeVideoFilesInYourGallery
            .youCanAlsoManageWhatMEGAStoresOnYourDevice(storageViewModel?.requiredStorageMemoryStyleString ?? "")

        firstButtonTitle = Strings.Localizable.manage

        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                let fileManagementVC = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "FileManagementTableViewControllerID")
                UIApplication.mnz_visibleViewController().navigationController?.pushViewController(fileManagementVC, animated: true)
            })
        }
        
        dismissButtonTitle = Strings.Localizable.notNow

        dismissCompletion = { [weak self] in
            guard let self else { return }
            dismiss(animated: true) {
                self.storageViewModel?.update(lastStoredDate: .now)
            }
        }
    }
}
