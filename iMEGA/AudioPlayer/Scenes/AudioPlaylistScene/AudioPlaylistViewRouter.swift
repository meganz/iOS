import Foundation
import MEGAAppPresentation
import MEGASwiftUI

final class AudioPlaylistViewRouter: NSObject, AudioPlaylistViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let parentNodeName: String
    
    init(
        parentNodeName: String,
        presenter: UIViewController
    ) {
        self.parentNodeName = parentNodeName
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let vc = UIStoryboard(name: "AudioPlayer", bundle: nil).instantiateViewController(withIdentifier: "AudioPlaylistViewControllerID") as! AudioPlaylistViewController

        vc.viewModel = AudioPlaylistViewModel(
            title: parentNodeName,
            router: self,
            tracker: DIContainer.tracker
        )
        baseViewController = vc
        
        return vc
    }
    
    @objc func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    func setPresenter(_ presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func showSnackBar(message: String) {
        guard let baseViewController else { return }
        baseViewController.showSnackBar(snackBar: SnackBar(message: message))
    }
}
