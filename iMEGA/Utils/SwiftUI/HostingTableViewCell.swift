import SwiftUI

final class HostingTableViewCell<Content: View>: UITableViewCell {
    private weak var controller: UIHostingController<Content>?
    
    func host(_ view: Content, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = view
        } else {
            let host = UIHostingController(rootView: view)
            controller = host
            
            parent.addChild(host)
            contentView.wrap(host.view)
            host.view.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
            host.didMove(toParent: parent)
        }
    }
}
