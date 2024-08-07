import MEGASwiftUI
import SwiftUI
import UIKit

public final class PhotosBrowserViewController: UIViewController {
    private let viewModel: PhotosBrowserViewModel
    
    private var navigationBar: UINavigationBar!
    private var toolbar: UIToolbar!
    
    // MARK: Constructor
    
    public init(viewModel: PhotosBrowserViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.red
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.buildNavigationBar)
        viewModel.dispatch(.buildBottomToolBar)
        viewModel.dispatch(.onViewReady)
    }
    
    // MARK: Private
    
    private func executeCommand(_ command: PhotosBrowserViewModel.Command) {
        switch command {
        case .buildBottomToolBar:
            buildBottomToolBar()
        case .buildNavigationBar:
            buildNavigationBar()
        case .onViewReady:
            break
        }
    }
    
    private func buildBottomToolBar() {
        toolbar = UIToolbar()
        view.addSubview(toolbar)
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.leftAnchor.constraint(equalTo: view.leftAnchor),
            toolbar.rightAnchor.constraint(equalTo: view.rightAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let config = ToolbarConfigurationFactory.configuration(on: viewModel.config.displayMode)
        config.configure(toolbar: toolbar, with: viewModel.config.toolbarImages, in: self)
    }
    
    private func buildNavigationBar() {
        navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        
        let navigationItem = UINavigationItem()
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let config = NavigationBarConfigurationFactory.configuration(on: viewModel.config.displayMode)
        config.configure(navigationItem: navigationItem, in: self)
        
        navigationBar.items = [navigationItem]
    }
}
