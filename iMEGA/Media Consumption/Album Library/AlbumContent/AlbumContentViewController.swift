import UIKit
import SwiftUI
import MEGAUIKit
import MEGADomain

@available(iOS 14.0, *)
final class AlbumContentViewController: UIViewController, ViewType, TraitEnviromentAware {
    private let viewModel: AlbumContentViewModel
    
    lazy var photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: PhotoLibraryContentMode.album)
    lazy var photoLibraryPublisher = PhotoLibraryPublisher(viewModel: photoLibraryContentViewModel)
    lazy var selection = PhotoSelectionAdapter(sdk: MEGASdkManager.sharedMEGASdk())
    
    lazy var rightBarButtonItem = UIBarButtonItem(
        image: Asset.Images.NavigationBar.selectAll.image,
        style: .plain,
        target: self,
        action: #selector(editButtonPressed(_:))
    )
    
    lazy var leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close,
                                                 style:.plain,
                                                 target: self,
                                                 action: #selector(exitButtonTapped(_:))
    )
    
    lazy var toolbar = UIToolbar()
    var albumToolbarConfigurator: AlbumToolbarConfigurator?
    
    private lazy var emptyView = EmptyStateView.create(for: .favourites)
    
    // MARK: - Init
    
    init(viewModel: AlbumContentViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildNavigationBar()
        
        configPhotoLibraryView(in: view)
        setupPhotoLibrarySubscriptions()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.onViewReady)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isToolbarShown {
            endEditingMode()
        }
        
        viewModel.cancelLoading()
    }
    
    // MARK: - Internal
    
    func selectedNodes() -> [MEGANode]? {
        selection.nodes
    }
    
    func endEditingMode() {
        setEditing(false, animated: true)
        
        enablePhotoLibraryEditMode(isEditing)
        configureBarButtons()
        hideNavigationEditBarButton(photoLibraryContentViewModel.library.isEmpty)
        
        navigationItem.title = viewModel.albumName
        
        hideToolbar()
    }
    
    func configureToolbarButtonsWithAlbumType() {
        configureToolbarButtons(albumType: viewModel.isFavouriteAlbum ? .favourite : .normal)
    }
    
    private func startEditingMode() {
        setEditing(true, animated: true)
        enablePhotoLibraryEditMode(isEditing)
        updateNavigationTitle(withSelectedPhotoCount: 0)
        
        configureBarButtons()
        configureToolbarButtonsWithAlbumType()
        
        showToolbar()
    }
    
    // MARK: - ViewType protocol
    
    func executeCommand(_ command: AlbumContentViewModel.Command) {
        switch command {
        case .showAlbum(let nodes):
            updatePhotoLibrary(by: nodes)
            
            if nodes.isEmpty {
                showEmptyView()
            }
            else {
                removeEmptyView()
            }
        case .dismissAlbum:
            dismiss(animated: true)
        }
    }
    
    
    // MARK: - Private
    
    private func buildNavigationBar() {
        self.title = viewModel.albumName
        
        configureBarButtons()
    }
    
    private func configureBarButtons() {
        configureLeftBarButton()
        configureRightBarButton()
    }
    
    private func configureLeftBarButton() {
        if isEditing {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: Asset.Images.NavigationBar.selectAll.image,
                style: .plain,
                target: self,
                action: #selector(selectAllButtonPressed(_:))
            )
        } else {
            leftBarButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.MediaDiscovery.exitButtonTint.color], for: .normal)
            navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }
    
    private func configureRightBarButton() {
        if isEditing {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelButtonPressed(_:))
            )
            navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.MediaDiscovery.exitButtonTint.color], for: .normal)
        } else {
            navigationItem.rightBarButtonItem = rightBarButtonItem
        }
    }
    
    private func showEmptyView() {
        view.addSubview(emptyView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        emptyView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }
    
    private func removeEmptyView() {
        emptyView.removeFromSuperview()
    }
    
    // MARK: - Action
    
    @objc private func exitButtonTapped(_ barButtonItem: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonPressed(_ barButtonItem: UIBarButtonItem) {
        endEditingMode()
    }
    
    @objc private func editButtonPressed(_ barButtonItem: UIBarButtonItem) {
        startEditingMode()
    }
    
    @objc private func selectAllButtonPressed(_ barButtonItem: UIBarButtonItem) {
        configPhotoLibrarySelectAll()
        configureToolbarButtonsWithAlbumType()
    }
    
    // MARK: - TraitEnviromentAware
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        AppearanceManager.forceToolbarUpdate(toolbar, traitCollection: traitCollection)
    }
}
