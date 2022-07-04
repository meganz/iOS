import UIKit
import SwiftUI
import Combine

@available(iOS 14.0, *)
final class PhotoAlbumContainerViewController: UIViewController {
    var photoViewController: PhotosViewController?
    var numberOfPages: Int = PhotoLibraryTab.allCases.count
    
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
    
    private let pageTabViewModel = PagerTabViewModel()
    private var subscriptions = Set<AnyCancellable>()
    private var pageTabHostingController: UIHostingController<PageTabView>?
    private var albumHostingController: UIViewController?
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpPhotosAndAlbumsControllers()
        setUpPagerTabView()
        setUpPageViewController()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        pageController.canScroll = false
        
        updatePageTabViewLayout()
        updatePageViewControllerLayout()
        
        coordinator.animate(alongsideTransition: nil) { _ in
            self.pageTabViewModel.tabOffset = Double(self.pageController.currentPage.index) * self.pageController.view.bounds.size.width / 2
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
    
    // MARK: - Private
    
    private func setUpPhotosAndAlbumsControllers() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Photos", bundle: nil)
        photoViewController = storyboard.instantiateViewController(withIdentifier: "photoViewController") as? PhotosViewController
        
        if let photoViewController = photoViewController {
            let photoUpdatePublisher = PhotoUpdatePublisher(photosViewController: photoViewController)
            let photoLibraryRepository = PhotoLibraryRepository.newRepo
            let fileSearchRepository = SDKFilesSearchRepository.newRepo
            let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository, searchRepository: fileSearchRepository)
            let viewModel = PhotoViewModel(
                photoUpdatePublisher: photoUpdatePublisher,
                photoLibraryUseCase: photoLibraryUseCase
            )
            photoViewController.viewModel = viewModel
            photoViewController.photoUpdatePublisher = photoUpdatePublisher
        }

        albumHostingController = AlbumListViewRouter().build()
        
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
        
        pageController.$currentPage
            .sink { [weak self] in
                self?.photoViewController?.hideRightBarButtonItem($0 == .timeline ? false : true)
            }
            .store(in: &subscriptions)
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
}
