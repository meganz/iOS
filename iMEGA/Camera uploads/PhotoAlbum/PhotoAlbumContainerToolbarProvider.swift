import UIKit
import MEGADomain

protocol PhotoAlbumContainerToolbarProvider {
    var isToolbarShown: Bool { get }
    
    func showToolbar()
    func hideToolbar()
    func updateToolbarDeleteButton(_ numOfItems: Int)
}

extension PhotoAlbumContainerViewController: PhotoAlbumContainerToolbarProvider {
    var isToolbarShown: Bool {
        return toolbar.superview != nil
    }
    
    func showToolbar() {
        guard let tabBarController = tabBarController else { return }
        guard !tabBarController.view.subviews.contains(toolbar) else { return }
        
        toolbar.alpha = 0.0
        tabBarController.view.addSubview(toolbar)
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        
        toolbar.topAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor, constant: 0).isActive = true
        toolbar.leadingAnchor.constraint(equalTo: tabBarController.tabBar.leadingAnchor, constant: 0).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: tabBarController.tabBar.trailingAnchor, constant: 0).isActive = true
    
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 1.0
        }
        
        updateToolbarDeleteButton(0)
    }
    
    func hideToolbar() {
        guard toolbar.superview != nil else { return }
        UIView.animate(withDuration: 0.3) {
            self.toolbar.alpha = 0.0
        } completion: { _ in
            self.toolbar.removeFromSuperview()
        }
    }
    
    @objc private func onDeleteAlbumConfirmation() {
        viewModel.showDeleteAlbumAlert.toggle()
    }
    
    var flexibleItem: UIBarButtonItem {
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                        target: nil,
                        action: nil)
    }
    
    func deleteButton(_ numOfItems: Int) -> UIBarButtonItem {
        let title = numOfItems > 0 ? Strings.Localizable.CameraUploads.Albums.delete(numOfItems) : Strings.Localizable.delete
        let deleteButton = UIBarButtonItem(title: title,
                                           style: .plain,
                                           target: self,
                                           action: #selector(onDeleteAlbumConfirmation))
        deleteButton.isEnabled = numOfItems > 0
        return deleteButton
    }
    
    func updateToolbarDeleteButton(_ numOfItems: Int) {
        toolbar.setItems([flexibleItem, deleteButton(numOfItems)], animated: false)
    }
}
