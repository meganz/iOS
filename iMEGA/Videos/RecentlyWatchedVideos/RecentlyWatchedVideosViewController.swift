import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIKit
import UIKit
import Video

final class RecentlyWatchedVideosViewController: UIViewController {
    
    private let videoConfig: VideoConfig
    private let recentlyOpenedNodesUseCase: any RecentlyOpenedNodesUseCaseProtocol
    private let sharedUIState: RecentlyWatchedVideosSharedUIState
    private let router: any VideoRevampRouting
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(
        videoConfig: VideoConfig,
        recentlyOpenedNodesUseCase: some RecentlyOpenedNodesUseCaseProtocol,
        sharedUIState: RecentlyWatchedVideosSharedUIState,
        router: some VideoRevampRouting,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.videoConfig = videoConfig
        self.recentlyOpenedNodesUseCase = recentlyOpenedNodesUseCase
        self.sharedUIState = sharedUIState
        self.router = router
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
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
        title = Strings.Localizable.Videos.RecentlyWatched.navigationBarTitle
        setupBarButtonItem()
    }
    
    private func setupBarButtonItem() {
        let rubbishBinBarButtonItem = UIBarButtonItem(image: MEGAAssets.UIImage.rubbishBin, primaryAction: UIAction(action: onTapRubbishBinBarButtonItem))
        navigationItem.rightBarButtonItems = [ rubbishBinBarButtonItem ]
        
        sharedUIState.$isRubbishBinBarButtonItemEnabled
            .receive(on: DispatchQueue.main)
            .sink { rubbishBinBarButtonItem.isEnabled = $0 }
            .store(in: &cancellables)
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeRecentlyWatchedVideosView(
            recentlyOpenedNodesUseCase: recentlyOpenedNodesUseCase,
            videoConfig: videoConfig,
            sharedUIState: sharedUIState,
            router: router,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider
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
            AppearanceManager.forceNavigationBarUpdate(navigationBar)
        }
    }
    
    private func onTapRubbishBinBarButtonItem() {
        sharedUIState.shouldShowDeleteAlert = true
    }
}
