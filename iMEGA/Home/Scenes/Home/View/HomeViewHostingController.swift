import Combine
import Home
import MEGAAppPresentation
import MEGASwiftUI
import SwiftUI

/// Lets the tab bar reset a tab's SwiftUI navigation to its root when the already-selected tab is tapped again.
///
/// UIKit automatically pops the tab's `UINavigationController` to its root on reselect, but Home hosts its
/// own SwiftUI `NavigationStack` inside the root hosting controller. That inner stack is invisible to UIKit,
/// so it must be reset explicitly.
@MainActor
protocol RootNavigationResettable {
    func resetNavigationToRoot()
}

final class HomeViewHostingController: UIViewController, AdsSlotDisplayable, SearchActivatable {
    private var isTabBarHidden: Binding<Bool> {
        Binding(
            get: { [weak self] in
                self?.tabBarController?.tabBar.isHidden ?? false
            },
            set: { [weak self] in
                self?.tabBarController?.tabBar.isHidden = $0
            }
        )
    }

    @Published var quickAccessRoute: QuickAccessRoute?

    private let popToRootSubject = PassthroughSubject<Void, Never>()

    private let dependency: HomeView.Dependency
    private let miniPlayerVisibility: MiniPlayerVisibility = MiniPlayerVisibility()
    private let tabBarSafeAreaInsetCompensation: TabBarSafeAreaInsetCompensation = TabBarSafeAreaInsetCompensation()
    private let homeDeepLink: HomeDeepLink = HomeDeepLink()
    private var shouldHandleSearchDeeplink = false

    private var cancelables: Set<AnyCancellable> = []
    
    init(dependency: HomeView.Dependency) {
        self.dependency = dependency
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMiniPlayerVisibility()
        startStreamingInfoServerIfNeeded()
        setupHomeView()
        navigationItem.backButtonDisplayMode = .minimal

        // Required to allow SwiftUI content (NavigationStack / ScrollView) to extend
        // under the tab bar when hosted inside a UINavigationController.
        // Without this, UIKit clamps the hosting view above the tab bar,
        // causing an unexpected bottom gap.
        extendedLayoutIncludesOpaqueBars = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Root cause: hiding the tab bar imperatively via `tabBar.isHidden` (around edit mode), plus a
        // background/foreground cycle, leaves the bottom safe area value stale, it stops accounting for the
        // visible tab bar.
        // The tab bar's frame height stays reliable, so we publish the gap between the two;
        // bottom-anchored SwiftUI content adds it as padding to stay above the tab bar (0 when the
        // safe area is correct, > 0 when stale).
        // Only iOS 26 exhibits the stale safe area; on earlier versions it stays correct, so any
        // compensation would double-pad and push the location button up — keep it at 0 there.
        if #available(iOS 26.0, *), let tabBar = tabBarController?.tabBar {
            let newValue = max(0, tabBar.frame.height - view.safeAreaInsets.bottom)
            if tabBarSafeAreaInsetCompensation.value != newValue {
                tabBarSafeAreaInsetCompensation.value = newValue
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureAdsVisibility()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        configureAdsVisibility()
    }

    private func setupHomeView() {
        let homeView = HomeView(
            dependency: dependency,
            homeDeepLink: homeDeepLink,
            tabBarHidden: isTabBarHidden,
            quickAccessRoutePublisher: $quickAccessRoute.eraseToAnyPublisher(),
            popToRootPublisher: popToRootSubject.eraseToAnyPublisher()
        )
        .environmentObject(miniPlayerVisibility)
        .environmentObject(tabBarSafeAreaInsetCompensation)

        let hostingViewController = UIHostingController(rootView: homeView)
        addChild(hostingViewController)
        
        let hostingView: UIView = hostingViewController.view
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingViewController.didMove(toParent: self)
    }

    // This is an old logic from the legacy home screen
    // whose purpose was to fix a bug in [IOS-7974]
    private func startStreamingInfoServerIfNeeded() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            let streamingInfoUseCase = StreamingInfoUseCase()
            streamingInfoUseCase.startServer()
        }
    }

    @objc func activateSearch() {
        homeDeepLink.homeSearch = true
    }
}

// MARK: - SnackBarLayoutCustomizable
extension HomeViewHostingController: SnackBarLayoutCustomizable {
    /// Temporary quick fix for the Home snackbar overlap on pre-iOS 26.
    ///
    /// Home currently shows the hide/unhide snackbar through the UIKit snackbar
    /// path, which anchors to this controller's `safeAreaLayoutGuide.bottomAnchor`.
    /// In the current Home hosting setup, combined with
    /// `extendedLayoutIncludesOpaqueBars = true`, that anchor can end up too low
    /// and place the snackbar behind the main tab bar.
    ///
    /// This inset compensates for the missing tab bar height so the snackbar is
    /// displayed correctly today. Keep this workaround narrow: our investigation
    /// suggests the root cause is architectural/layout-related, and likely tied
    /// to Home's hosting/container geometry differing from Cloud Drive.
    var additionalSnackBarBottomInset: CGFloat {
        guard #unavailable(iOS 26),
              let tabBar = tabBarController?.tabBar,
              !tabBar.isHidden else {
            return 0
        }

        return max(tabBar.frame.height - view.safeAreaInsets.bottom, 0)
    }
}

extension HomeViewHostingController: AudioPlayerPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        miniPlayerVisibility.height = height
    }

    public func hasUpdatedContentView() -> Bool {
        miniPlayerVisibility.height != 0
    }

    func setupMiniPlayerVisibility() {
        miniPlayerVisibility
            .$isHidden
            .sink { hidden in
                if AudioPlayerManager.shared.isPlayerAlive() {
                    AudioPlayerManager.shared.playerHidden(hidden)
                }
            }
            .store(in: &cancelables)
    }
}
extension HomeViewHostingController: RootNavigationResettable {
    func resetNavigationToRoot() {
        popToRootSubject.send(())
    }
}

extension HomeViewHostingController: QuickAccessRouting {
    func handle(quickAccessRoute: QuickAccessRoute) {
        self.quickAccessRoute = quickAccessRoute
    }
}

extension HomeViewHostingController: TextFileEditable {}
