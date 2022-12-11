import Foundation
import SwiftUI

protocol VerifyCredentialsViewProvider: UIViewController {
    var warningViewModel: WarningViewModel { get }
    func configWarningView(in container: UIView)
    func updateWarningViewSize()
    func removeWarningView()
}

extension VerifyCredentialsViewProvider {
    func configWarningView(in container: UIView) {
        let content = WarningView(viewModel: warningViewModel)
        
        let host = UIHostingController(rootView: content)
        addChild(host)
        container.wrap(host.view)
        host.view.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
        host.didMove(toParent: self)
    }
    
    func updateWarningViewSize() {
        guard let host = children.first(where: { $0 is UIHostingController<WarningView> }) else {
            return
        }
        host.view.invalidateIntrinsicContentSize()
    }
    
    func removeWarningView() {
        guard let host = children.first(where: { $0 is UIHostingController<WarningView> }) else {
            return
        }
        host.view.removeFromSuperview()
    }
}
