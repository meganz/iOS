import Foundation

final class AudioPlaylistViewRouter: NSObject, AudioPlaylistViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private weak var playerHandler: AudioPlayerHandlerProtocol?
    private var parentNode: MEGANode?
    
    init(presenter: UIViewController, parentNode: MEGANode?, playerHandler: AudioPlayerHandlerProtocol?) {
        self.presenter = presenter
        self.parentNode = parentNode
        self.playerHandler = playerHandler
        super.init()
    }
    
    func build() -> UIViewController {
        let vc = UIStoryboard(name: "AudioPlayer", bundle: nil).instantiateViewController(withIdentifier: "AudioPlaylistViewControllerID") as! AudioPlaylistViewController

        vc.viewModel = AudioPlaylistViewModel(router: self, parentNode: parentNode, nodeInfoUseCase: NodeInfoUseCase(), playerHandler: playerHandler)
        baseViewController = vc
        
        return vc
    }
    
    @objc func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
}
