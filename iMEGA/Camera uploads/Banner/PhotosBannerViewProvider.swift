import Foundation
import SwiftUI

protocol PhotosBannerViewProvider: UIViewController {
    var photosBannerViewModel: PhotosBannerViewModel { get }
    
    func configPhotosBannerView(in container: UIView)
    func updatePhotoBannerViewSize()
}

extension PhotosBannerViewProvider {
    func configPhotosBannerView(in container: UIView) {
        let content = PhotosBannerView(
            viewModel: photosBannerViewModel,
            router: PhotosBannerViewRouter()
        )
        
        let host = UIHostingController(rootView: content)
        addChild(host)
        container.wrap(host.view)
        host.view.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        host.didMove(toParent: self)
    }
    
    func updatePhotoBannerViewSize() {
        guard let host = children.first(where: { $0 is UIHostingController<PhotosBannerView> }) else {
            return
        }
        host.view.invalidateIntrinsicContentSize()
    }
}
