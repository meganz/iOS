import Foundation
import SwiftUI

protocol PhotosBannerViewProvider: UIViewController {
    var warningViewModel: WarningViewModel { get }
    
    func configPhotosBannerView(in container: UIView)
    func updatePhotoBannerViewSize()
}

extension PhotosBannerViewProvider {
    func configPhotosBannerView(in container: UIView) {
        let content = WarningView(viewModel: warningViewModel)
        
        let host = UIHostingController(rootView: content)
        addChild(host)
        container.wrap(host.view)
        host.view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        host.didMove(toParent: self)
    }
    
    func updatePhotoBannerViewSize() {
        guard let host = children.first(where: { $0 is UIHostingController<WarningView> }) else {
            return
        }
        host.view.invalidateIntrinsicContentSize()
    }
}
