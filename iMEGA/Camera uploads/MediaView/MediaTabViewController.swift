import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADesignToken
import SwiftUI
import UIKit

// MARK: - MediaTabHostingController

final class MediaTabViewController: UIViewController {

    // MARK: - Properties

    let viewModel: MediaTabViewModel
    let tracker: any AnalyticsTracking
    private var toolbarItemsFactory: MediaBottomToolbarItemsFactory
    private var subscriptions = Set<AnyCancellable>()

    private lazy var toolbarCoordinator = MediaTabToolbarCoordinator(viewController: self)

    lazy var toolbar = UIToolbar()
    
    private var hostingController: UIHostingController<MediaTabView>?
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.searchBar.delegate = self
        controller.delegate = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = true
        controller.searchBar.isTranslucent = false
        return controller
    }()
    
    private var isExitingSearch = false
    
    var nodeActionDisplayMode: DisplayMode {
        viewModel.nodeActionDisplayMode
    }

    // MARK: - Initialization

    init(
        viewModel: MediaTabViewModel,
        toolbarItemsFactory: MediaBottomToolbarItemsFactory,
        tracker: any AnalyticsTracking = DIContainer.tracker
    ) {
        self.viewModel = viewModel
        self.toolbarItemsFactory = toolbarItemsFactory
        self.tracker = tracker

        super.init(nibName: nil, bundle: nil)

        self.toolbarItemsFactory.actionDelegate = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
        setupNavigationBar()
        setupNavigationBarObservers()
        setupToolbarObservers()
        injectToolbarCoordinator()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hideToolbar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Fixes TabView layout issues caused by AdsSlotView loading ads at the bottom.
        // This issue only occurs in iOS 26 Liquid Glass mode.
        refreshLayoutIfNeeded()
    }

    private func refreshLayoutIfNeeded() {
        guard #available(iOS 26.0, *) else { return }
        viewModel.layoutRevision = UUID()
    }

    // MARK: - Content View Setup

    private func setupContentView() {
        let rootView = MediaTabView(viewModel: viewModel)
        let hosting = UIHostingController(rootView: rootView)
        hostingController = hosting

        add(hosting, container: view, animate: false)
    }

    // MARK: - Navigation Bar Setup

    private func setupNavigationBar() {
        navigationItem.titleView = makeTitleView()
        updateNavigationBarItems()
    }

    private func makeTitleView() -> UIView {
        let titleView = UILabel.customNavigationBarLabel(
            title: viewModel.navigationTitle,
            subtitle: viewModel.navigationSubtitle
        )
        titleView.sizeToFit()
        return titleView
    }

    private func updateTitleView() {
        navigationItem.titleView = makeTitleView()
    }

    private func updateNavigationBarItems() {
        let leadingViewModels = viewModel.leadingNavigationBarViewModels
        let trailingViewModels = viewModel.trailingNavigationBarViewModels

        navigationItem.leftBarButtonItems = if leadingViewModels.isEmpty {
            nil
        } else {
            leadingViewModels.map { makeBarButtonItem(from: $0) }
        }
        
        navigationItem.rightBarButtonItems = if trailingViewModels.isEmpty {
            nil
        } else {
            trailingViewModels.reversed().map { makeBarButtonItem(from: $0) }
        }
    }

    private func makeBarButtonItem(from viewModel: NavigationBarItemViewModel) -> UIBarButtonItem {
        // For text buttons, use native UIBarButtonItem to preserve standard appearance
        if case .textButton(let text, let action) = viewModel.viewType {
            return UIBarButtonItem(
                title: text,
                primaryAction: UIAction { _ in action() }
            )
        }

        // For other types, wrap SwiftUI view in UIHostingController
        let swiftUIView = NavigationBarItemViewBuilder.makeView(for: viewModel)
        let hostingController = UIHostingController(rootView: AnyView(swiftUIView))
        hostingController.view.backgroundColor = .clear
        hostingController.view.sizeToFit()
        return UIBarButtonItem(customView: hostingController.view)
    }
    
    // MARK: - Navigation Bar Observers
    
    private func setupNavigationBarObservers() {
        viewModel.$navigationTitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateTitleView() }
            .store(in: &subscriptions)

        viewModel.$navigationSubtitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateTitleView() }
            .store(in: &subscriptions)

        viewModel.$navigationBarItemViewModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateNavigationBarItems() }
            .store(in: &subscriptions)

        viewModel.$isSearching
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSearching in
                self?.updateSearchMode(isSearching: isSearching)
            }
            .store(in: &subscriptions)
    }

    private func updateSearchMode(isSearching: Bool) {
        if isSearching {
            isExitingSearch = false
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            definesPresentationContext = true
            navigationController?.view.layoutIfNeeded()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.searchController.isActive = true
                self.searchController.searchBar.becomeFirstResponder()
            }
        } else {
            guard navigationItem.searchController != nil else { return }
            // Mark that we're exiting search - actual cleanup happens in didDismissSearchController
            isExitingSearch = true
            // Just deactivate, don't remove searchController yet
            searchController.isActive = false
        }
    }

    // MARK: - Coordinator Injection

    private func injectToolbarCoordinator() {
        // Inject coordinator into all tab view models
        for (_, tabViewModel) in viewModel.tabViewModels {
            if let toolbarActionViewModel = tabViewModel as? any MediaTabToolbarActionHandler {
                toolbarActionViewModel.toolbarCoordinator = toolbarCoordinator
            }
        }
    }

    // MARK: - Toolbar Observers

    private func setupToolbarObservers() {
        viewModel.$showToolbar
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                guard let self else { return }
                if shouldShow, let config = viewModel.toolbarConfig {
                    self.showToolbar(with: config)
                } else {
                    self.hideToolbar()
                }
            }
            .store(in: &subscriptions)

        viewModel.$toolbarConfig
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] config in
                self?.updateToolbar(with: config)
            }
            .store(in: &subscriptions)
    }
}

// MARK: - UISearchResultsUpdating

extension MediaTabViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        viewModel.searchText.wrappedValue = searchText
    }
}

// MARK: - UISearchBarDelegate

extension MediaTabViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Mark intent to exit, actual state change happens after dismiss completes
        isExitingSearch = true
    }
}

// MARK: - UISearchControllerDelegate

extension MediaTabViewController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        // Only cleanup if we're intentionally exiting search
        guard isExitingSearch else { return }
        isExitingSearch = false

        // Now safe to remove searchController and update state
        navigationItem.searchController = nil
        viewModel.isSearching = false
    }
}

// MARK: - MediaToolbarProvider

extension MediaTabViewController: MediaToolbarProvider {

    func updateToolbar(with config: MediaBottomToolbarConfig) {
        let items = toolbarItemsFactory.buildToolbarItems(config: config)

        let flexibleSpace = UIBarButtonItem.flexibleSpace
        toolbar.items = items.flatMap { item in
            item == items.last ? [item] : [item, flexibleSpace]
        }
    }
}

// MARK: - MediaToolbarActionDelegate

extension MediaTabViewController: MediaToolbarActionDelegate {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        // Delegate to the view model, which will route to the appropriate tab view model
        viewModel.handleToolbarItemAction(action)
    }
}

// MARK: - BottomOverlayPresenterProtocol

extension MediaTabViewController: BottomOverlayPresenterProtocol {
    func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }

    func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
