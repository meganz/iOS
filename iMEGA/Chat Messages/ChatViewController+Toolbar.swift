import UIKit

enum ToolbarType {
    case delete
    case forward
}

extension ChatViewController {
    func customToolbar(type: ToolbarType) {
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        switch type {
        case .forward:
            setToolbarItems([shareBarButtonItem, flexibleItem, forwardBarButtonItem], animated: true)
        case .delete:
            setToolbarItems([deleteBarButtonItem], animated: true)
        }
    }
    
    
    @objc func deleteSelectedMessages() {
        
    }
    
    @objc func forwardSelectedMessages() {
//        ind
    }
    
    @objc func shareSelectedMessages() {
        
    }
}

