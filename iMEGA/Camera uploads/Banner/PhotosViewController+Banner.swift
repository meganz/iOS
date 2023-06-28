import Photos
import SwiftUI
import UIKit

extension PhotosViewController: PhotosBannerViewProvider {
    @objc func createWarningViewModel() -> WarningViewModel {
        WarningViewModel(warningType: .limitedPhotoAccess, router: WarningViewRouter())
    }
    
    @objc func objcWrapper_configPhotosBannerView() {
        configPhotosBannerView(in: photosBannerView)
    }
    
    var permissionHandler: DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    var shouldShowPhotosBanner: Bool {
        // we should show banner if we enabled the camera upload
        // but did not enable access to whole library
        CameraUploadManager.isCameraUploadEnabled &&
        permissionHandler.photoLibraryAuthorizationStatus == .limited
    }
    
    @objc
    func updateLimitedAccessBannerVisibility() {
        showPhotosBannerView(show: shouldShowPhotosBanner)
    }
    
    private func showPhotosBannerView(show: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.photosBannerView.isHidden = !show
        }
    }

    @objc func updateBannerViewIfNeeded(previousTraitCollection: UITraitCollection?) {
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            self.updatePhotoBannerViewSize()
        }
    }
}
