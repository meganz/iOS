import UIKit
import SwiftUI
import Combine
import MEGADomain
import MEGAUIKit

final class PhotoAlbumContainerViewController: UIViewController, TraitEnviromentAware {
    var photoViewController: PhotosViewController?
    var numberOfPages: Int = PhotoLibraryTab.allCases.count
    
    lazy var toolbar = UIToolbar()
    
    override var isEditing: Bool {
        willSet {
            pageTabViewModel.isEditing = newValue
            pageController.dataSource = newValue ? nil : self
            pageTabHostingController?.view?.isUserInteractionEnabled = !newValue
        }
    }
    
    private lazy var pageController: PhotosPageViewController = {
        PhotosPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }()
    
    let pageTabViewModel = PagerTabViewModel()
    let viewModel = PhotoAlbumContainerViewModel()
    let featureFlagProvider: FeatureFlagProviderProtocol = FeatureFlagProvider()
    
    private var subscriptions = Set<AnyCancellable>()
    private var pageTabHostingController: UIHostingController<PageTabView>?
    private var albumHostingController: UIViewController?
    
    var leftBarButton: UIBarButtonItem?
    lazy var isAlbumShareLinkEnabled = featureFlagProvider.isFeatureFlagEnabled(for: .albumShareLink)
    lazy var shareLinkBarButton = UIBarButtonItem(image: Asset.Images.Generic.link.image,
                                               style: .plain,
                                               target: self,
                                               action: #selector(shareLinksButtonPressed))
    lazy var removeLinksBarButton = UIBarButtonItem(image: Asset.Images.NodeActions.removeLink.image,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(removeLinksButtonPressed))
    lazy var deleteBarButton = UIBarButtonItem(image: Asset.Images.NodeActions.rubbishBin.image,
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(deleteAlbumButtonPressed))
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setUpPhotosAndAlbumsControllers()
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpPagerTabView()
        setUpPageViewController()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        pageController.canScroll = false
        
        updatePageTabViewLayout()
        updatePageViewControllerLayout()
        
        coordinator.animate(alongsideTransition: nil) { _ in
            self.pageTabViewModel.tabOffset = CGFloat(self.pageController.currentPage.index) * self.pageController.view.bounds.size.width / 2
            self.pageController.canScroll = true
        }
    }
    
    // MARK: Internal
    
    func showViewController(at page: PhotoLibraryTab) -> UIViewController? {
        var currentViewController: UIViewController?
        
        switch page {
        case .timeline: currentViewController = photoViewController
        case .album: currentViewController = albumHostingController
        }
        
        return currentViewController
    }
    
    func page(of viewController: UIViewController?) -> PhotoLibraryTab {
        switch viewController {
        case is PhotosViewController:
            return .timeline
        case is UIHostingController<AlbumListView>:
            return .album
        default:
            return .timeline
        }
    }
    
    func updateCurrentPage(_ page: PhotoLibraryTab) {
        pageController.currentPage = page
        pageTabViewModel.selectedTab = page
    }
    
    func isTimelineActive() -> Bool {
        pageTabViewModel.selectedTab == .timeline
    }
    
    // MARK: - TraitEnviromentAware
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if pageTabViewModel.selectedTab == .album {
                updateBarButtons()
            }
        }
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        if pageTabViewModel.selectedTab == .album {
            AppearanceManager.forceToolbarUpdate(toolbar, traitCollection: traitCollection)
        }
    }
    
    // MARK: - Private
    
    private func setUpPhotosAndAlbumsControllers() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Photos", bundle: nil)
        photoViewController = storyboard.instantiateViewController(withIdentifier: "photoViewController") as? PhotosViewController
        
        if let photoViewController = photoViewController {
            let photoUpdatePublisher = PhotoUpdatePublisher(photosViewController: photoViewController)
            let photoLibraryRepository = PhotoLibraryRepository.newRepo
            let fileSearchRepository = FilesSearchRepository.newRepo
            let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository, searchRepository: fileSearchRepository)
            let viewModel = PhotosViewModel(
                photoUpdatePublisher: photoUpdatePublisher,
                photoLibraryUseCase: photoLibraryUseCase
            )
            photoViewController.viewModel = viewModel
            photoViewController.photoUpdatePublisher = photoUpdatePublisher
        }

        albumHostingController = AlbumListViewRouter(photoAlbumContainerViewModel: viewModel).build()
        
        photoViewController?.parentPhotoAlbumsController = self
        photoViewController?.configureMyAvatarManager()
    }
    
    private func setUpPagerTabView() {
        let content = PageTabView(viewModel: pageTabViewModel)
        pageTabHostingController = UIHostingController(rootView: content)
        
        guard let hostingController = pageTabHostingController else { return }
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        updatePageTabViewLayout()
        
        hostingController.didMove(toParent: self)
        
        pageTabViewModel.$selectedTab.sink { [weak self] in
            if let viewController = self?.showViewController(at: $0) {
                self?.pageController.setViewControllers([viewController], direction: $0 == .album ? .forward : .reverse, animated: true, completion: nil)
                self?.pageController.currentPage = $0
            }
        }
        .store(in: &subscriptions)
    }
    
    private func setUpPageViewController() {
        addChild(pageController)
        view.addSubview(pageController.view)
        
        leftBarButton = navigationItem.leftBarButtonItem
        
        pageController.dataSource = self
        pageController.delegate = self
        
        if let viewController = showViewController(at: .timeline) {
            pageController.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
        }
        
        updatePageViewControllerLayout()
        
        pageController.didMove(toParent: self)
        
        pageController.$pageOffset
            .dropFirst()
            .filter { $0 >= 0 && $0 <= self.view.bounds.size.width / 2 }
            .sink { [weak self] in
                self?.pageTabViewModel.tabOffset = $0
            }
            .store(in: &subscriptions)
        
        pageTabViewModel.$selectedTab
            .filter { $0 == .album }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRightBarButton()
            }
            .store(in: &subscriptions)
        
        viewModel.$shouldShowSelectBarButton
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRightBarButton()
            }
            .store(in: &subscriptions)
        
        viewModel.$editMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isEditing = $0 == .active
                if !$0.isEditing {
                    self?.updateBarButtons()
                }
            }
            .store(in: &subscriptions)
        
        viewModel.$isAlbumsSelected
            .removeDuplicates()
            .sink { [weak self] in
                guard let self else { return }
                updateToolbarButtonEnabledState(isSelected: $0)
            }
            .store(in: &subscriptions)
        
        if isAlbumShareLinkEnabled {
            viewModel.$isOnlyExportedAlbumsSelected
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard let self else { return }
                    updateRemoveLinksToolbarButtons(canRemoveLinks: $0)
                }
                .store(in: &subscriptions)
        }
    }
    
    private func updatePageTabViewLayout() {
        guard let hostingController = pageTabHostingController else { return }
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: 38)
        ])
    }
    
    private func updatePageViewControllerLayout() {
        guard let hostingController = pageTabHostingController else { return }
        self.pageController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.pageController.view.topAnchor.constraint(equalTo: hostingController.view.bottomAnchor, constant: 2),
            self.pageController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.pageController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.pageController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func deleteAlbumButtonPressed() {
        viewModel.showDeleteAlbumAlert.toggle()
    }
    
    @objc private func shareLinksButtonPressed() {
        viewModel.showShareAlbumLinks.toggle()
    }
    
    @objc private func removeLinksButtonPressed() {
        viewModel.showRemoveAlbumLinksAlert.toggle()
    }
}
