import FolderLink
import SwiftUI
import UIKit

final class NewFolderLinkViewController: UIViewController {
    private let link: String
    
    init(link: String) {
        self.link = link
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attachFolderLinkView()
    }
    
    private func attachFolderLinkView() {
        navigationController?.navigationBar.isHidden = true
        
        let dependency = FolderLinkView.Dependency(
            link: link,
            onClose: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
        let folderLinkViewController = UIHostingController(rootView: FolderLinkView(dependency: dependency))
        addChild(folderLinkViewController)
        let folderLinkView: UIView = folderLinkViewController.view
        view.addSubview(folderLinkView)
        folderLinkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            folderLinkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            folderLinkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            folderLinkView.topAnchor.constraint(equalTo: view.topAnchor),
            folderLinkView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        folderLinkViewController.didMove(toParent: self)
    }
}
