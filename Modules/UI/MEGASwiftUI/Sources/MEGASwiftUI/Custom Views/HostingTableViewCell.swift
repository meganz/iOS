import SwiftUI

final public class HostingTableViewCell<Content: View>: UITableViewCell {
    private weak var controller: UIHostingController<Content>?
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        if #available(iOS 16.0, *) {
            contentConfiguration = nil
        }
    }
    
    public func host(_ view: Content, parent: UIViewController) {
        if #available(iOS 16.0, *) {
            contentConfiguration = UIHostingConfiguration {
                view
            }
            .margins(.all, 0)
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
