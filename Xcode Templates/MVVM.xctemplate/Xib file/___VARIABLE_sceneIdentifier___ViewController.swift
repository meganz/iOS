import UIKit

final class ___VARIABLE_sceneName:identifier___ViewController: UIViewController, ViewType {
    // MARK: - Private properties

    // MARK: - Internal properties
    var viewModel : ___VARIABLE_sceneName:identifier___ViewModel!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            DispatchQueue.main.async { self?.executeCommand(command) }
        }
        
        viewModel.dispatch(.onViewLoaded)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            
            updateAppearance()
        }
    }
    
    // MARK: - UI actions

    // MARK: - UI configurations
    private func updateAppearance() {
    
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: ___VARIABLE_sceneName:identifier___ViewModel.Command) {
//        switch command {
//        case .:
//        case .:
//        }
    }
}
