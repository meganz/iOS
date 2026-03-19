import Home
import SwiftUI

final class HomeViewHostingController: UIViewController, AdsSlotDisplayable {
    private var isTabBarHidden: Binding<Bool> {
        Binding(
            get: {
                self.tabBarController?.tabBar.isHidden ?? false
            },
            set: {
                self.tabBarController?.tabBar.isHidden = $0
            }
        )
    }
    
    private let dependency: HomeView.Dependency
    
    init(dependency: HomeView.Dependency) {
        self.dependency = dependency
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHomeView()
        navigationItem.backButtonDisplayMode = .minimal

        // Required to allow SwiftUI content (NavigationStack / ScrollView) to extend
        // under the tab bar when hosted inside a UINavigationController.
        // Without this, UIKit clamps the hosting view above the tab bar,
        // causing an unexpected bottom gap.
        extendedLayoutIncludesOpaqueBars = true
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
            tabBarHidden: isTabBarHidden
        )
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
}
