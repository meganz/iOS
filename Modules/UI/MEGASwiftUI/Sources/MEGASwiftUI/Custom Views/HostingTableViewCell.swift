import SwiftUI

final public class HostingTableViewCell<Content: View>: UITableViewCell {
    private weak var controller: UIHostingController<Content>?
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        contentConfiguration = nil
    }
    
    public func host(_ view: Content, parent: UIViewController) {
        contentConfiguration = UIHostingConfiguration {
            view
        }
        .margins(.all, 0)
    }
}
