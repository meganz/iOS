import SwiftUI
import UIKit
import Photos

extension PhotosViewController: PhotosBannerViewProvider {
    @objc func createWarningViewModel() -> WarningViewModel {
        WarningViewModel(warningType: .limitedPhotoAccess, router: WarningViewRouter())
    }
    
    @objc func objcWrapper_configPhotosBannerView() {
        configPhotosBannerView(in: photosBannerView)
    }
    
    @objc func updateLimitedAccessBannerVisibility() {
        guard CameraUploadManager.isCameraUploadEnabled,
              PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else {
            showPhotosBannerView(isHidden: true)
            return
        }
        
        showPhotosBannerView(isHidden: false)
    }
    
    private func showPhotosBannerView(isHidden: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.photosBannerView.isHidden = isHidden
        }
    }

    @objc func updateBannerViewIfNeeded(previousTraitCollection: UITraitCollection?) {
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            self.updatePhotoBannerViewSize()
        }
    }
}
