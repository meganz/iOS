import SwiftUI
import UIKit
import Photos

extension PhotosViewController: PhotosBannerViewProvider {
    @objc func createPhotosBannerViewModel() -> PhotosBannerViewModel {
        PhotosBannerViewModel(message: Strings.Localizable.CameraUploads.Warning.limitedAccessToPhotoMessage)
    }
    
    @objc func objcWrapper_configPhotosBannerView() {
        configPhotosBannerView(in: photosBannerView)
    }
    
    @objc func updateLimitedAccessBannerVisibility() {
        guard #available(iOS 14, *),
              CameraUploadManager.isCameraUploadEnabled,
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
