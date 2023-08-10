import AVFoundation
import UIKit

final class MEGAAVViewControllerLoadingDecorator: UIViewController {
    private(set) var decoratee: MEGAAVViewController
    private(set) var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    
    init(decoratee: MEGAAVViewController) {
        self.decoratee = decoratee
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        decoratee.avViewControllerDelegate = self
        configureAsChild(decoratee)
        configureActivityIndicator()
    }
    
    private func configureAsChild(_ controller: UIViewController) {
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.frame = view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.didMove(toParent: self)
    }
    
    private func configureActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

extension MEGAAVViewControllerLoadingDecorator: MEGAAVViewControllerDelegate {
    
    func willStartPlayer() {
        activityIndicator.startAnimating()
    }
    
    func didStartPlayer() {
        activityIndicator.stopAnimating()
    }
    
    func didChangePlayerItemStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .unknown, .readyToPlay, .failed:
            activityIndicator.stopAnimating()
        default:
            break
        }
    }
    
    func playerDidStall() {
        activityIndicator.startAnimating()
    }
    
    func playerDidChangeTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .waitingToPlayAtSpecifiedRate:
            activityIndicator.startAnimating()
        default:
            activityIndicator.stopAnimating()
        }
    }
}
