import MEGADesignToken
import MEGAUIKit
import UIKit
import Video

final class RecentlyWatchedVideosViewController: UIViewController {
    
    private let videoConfig: VideoConfig
    
    init(videoConfig: VideoConfig) {
        self.videoConfig = videoConfig
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForTraitChanges()
        setupNavigationBar()
        setupContentView()
    }
    
    private func setupNavigationBar() {
        forceNavigationBarUpdateIfNeeded()
        title = "Recently watched" // CC-7877
        setupBarButtonItem()
    }
    
    private func setupBarButtonItem() {
        let rubbishBinBarButtonItem = UIBarButtonItem(image: UIImage.rubbishBin, primaryAction: nil)
        navigationItem.rightBarButtonItems = [ rubbishBinBarButtonItem ]
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeRecentlyWatchedVideosView(
            videoConfig: videoConfig
        )
        add(contentView, container: view, animate: false)
    }
    
    private func registerForTraitChanges() {
        guard #available(iOS 17.0, *) else { return }
        registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { [weak self] (viewController: RecentlyWatchedVideosViewController, previousTraitCollection: UITraitCollection) in
            self?.handleTraitCollectionChange(previousTraitCollection, newestTraitCollection: viewController.traitCollection)
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0) {
            guard let previousTraitCollection else { return }
            handleTraitCollectionChange(previousTraitCollection, newestTraitCollection: traitCollection)
        }
    }
    
    private func handleTraitCollectionChange(_ previousTraitCollection: UITraitCollection, newestTraitCollection: UITraitCollection) {
        if newestTraitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle {
            forceNavigationBarUpdateIfNeeded()
        }
    }
    
    private func forceNavigationBarUpdateIfNeeded() {
        if let navigationBar = navigationController?.navigationBar {
            AppearanceManager.forceNavigationBarUpdate(navigationBar, traitCollection: traitCollection)
        }
    }
}
