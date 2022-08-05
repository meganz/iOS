import SwiftUI
import MEGADomain

struct PhotoBrowser: UIViewControllerRepresentable {
    let currentPhoto: NodeEntity
    let allPhotos: [NodeEntity]
    
    func makeUIViewController(context: Context) -> MEGAPhotoBrowserViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let browser = MEGAPhotoBrowserViewController.photoBrowser(
            with: PhotoBrowserDataProvider(currentPhoto: currentPhoto, allPhotos: allPhotos, sdk: sdk),
            api: sdk,
            displayMode: .cloudDrive
        )
        browser.needsReload = true
        return browser
    }
    
    func updateUIViewController(_ uiViewController: MEGAPhotoBrowserViewController, context: Context) {}
}
