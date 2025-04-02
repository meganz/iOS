import Foundation
import MEGAPresentation

final class AudioPlaylistViewRouter: NSObject, AudioPlaylistViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private var configEntity: AudioPlayerConfigEntity
    
    init(configEntity: AudioPlayerConfigEntity, presenter: UIViewController) {
        self.configEntity = configEntity
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let vc = UIStoryboard(name: "AudioPlayer", bundle: nil).instantiateViewController(withIdentifier: "AudioPlaylistViewControllerID") as! AudioPlaylistViewController

        vc.viewModel = AudioPlaylistViewModel(
            configEntity: configEntity,
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
}
