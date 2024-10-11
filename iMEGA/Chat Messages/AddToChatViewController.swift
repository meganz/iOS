import MEGADesignToken
import MEGAPermissions
import UIKit

protocol AddToChatViewControllerDelegate: AnyObject {
    func send(asset: PHAsset)
    func loadPhotosView()
    func showCamera()
    func showCloudDrive()
    func showVoiceClip()
    func showContacts()
    func showScanDoc()
    func showLocation()
    func showGiphy()
    func showFilesApp()
    
    var canRecordAudio: Bool { get }
    func requestOrInformAudioPermissions()
    
    var existsActiveCall: Bool { get }
    func presentActiveCall()
}

class AddToChatViewController: UIViewController {
    
    // MARK: - Properties.
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet private weak var patchView: UIView!
    @IBOutlet private weak var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet private weak var mediaCollectionView: UICollectionView!
    @IBOutlet private weak var mediaCollectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var mediaCollectionViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var menuView: UIView!
    @IBOutlet private weak var menuViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var menuViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var menuViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var pageControlBottomConstraint: NSLayoutConstraint!

    var dismissHandler: (() -> Void)?
    private var presentAndDismissAnimationDuration: TimeInterval = 0.4
    private var mediaCollectionSource: AddToChatMediaCollectionSource?
    private var menuPageViewController: AddToChatMenuPageViewController?

    weak var addToChatDelegate: (any AddToChatViewControllerDelegate)?
    
    private let iPadPopoverWidth: CGFloat = 340.0
    
    // MARK: - View lifecycle methods.
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        if UIDevice.current.iPadDevice == false {
            definesPresentationContext = true
            modalPresentationStyle = .overCurrentContext
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaCollectionSource = AddToChatMediaCollectionSource(
            collectionView: mediaCollectionView,
            delegate: self,
            permissionHandler: permissionHandler
        )
        setUpMenuPageViewController()
        
        if UIDevice.current.iPadDevice == false {
            contentView.layer.cornerRadius = 13.0
        } else {
            backgroundView.isHidden = true
        }
        
        updateAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIDevice.current.iPadDevice {
            let maxWidth = UIApplication.shared.keyWindow?.bounds.width ?? UIScreen.main.bounds.width
            preferredContentSize = requiredSize(forWidth: min((maxWidth-20), iPadPopoverWidth))
        }
        
        updateContentViewConstraints()
        mediaCollectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UIDevice.current.iPadDevice {
            presentationAnimationComplete()
        }        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        contentViewHeightConstraint.constant = requiredSize(forWidth: contentView.bounds.width).height
        
        // The content view height is adjusted to maintain the aspect ratio of the each menu size.
        // If the height of the view does not match that of the content then need to center the content
        if preferredContentSize.height != 0 &&
            contentViewHeightConstraint.constant != preferredContentSize.height {
            contentViewBottomConstraint.constant = (view.bounds.height - contentViewHeightConstraint.constant) / 2.0
        } else if contentViewBottomConstraint.constant != 0.0 {
            contentViewBottomConstraint.constant = 0.0
        }
        
        // If the photo collection is not shown the authorization text message cell should fill the collectionView.
        
        if permissionHandler.photoLibraryAuthorizationStatus != .authorized {
            debounce(#selector(reloadMediaCollectionView), delay: 0.3)
        }
    }
    
    private var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    @objc func reloadMediaCollectionView() {
        mediaCollectionView.reloadData()
    }
    
    func presentationAnimationComplete() {
        mediaCollectionSource?.showLiveFeedIfRequired = true
    }
    
    func requiredSize(forWidth width: CGFloat) -> CGSize {
        guard let menuPageViewController = menuPageViewController else {
            return .zero
        }
        
        let menuPageViewControllerHorizontalPadding = menuViewLeadingConstraint.constant + menuViewTrailingConstraint.constant
        let menuPageViewControllerHeight = menuPageViewController.totalRequiredHeight(forWidth: width,
                                                                                      horizontalPaddding: menuPageViewControllerHorizontalPadding)

        let pageControlHeight = pageControl.bounds.height
            + pageControlBottomConstraint.constant
        
        let mediaCollectionViewHeight = mediaCollectionView.bounds.height
            + mediaCollectionViewBottomConstraint.constant
            + mediaCollectionViewTopConstraint.constant
        
        let height = menuPageViewControllerHeight
            + mediaCollectionViewHeight
            + menuViewBottomConstraint.constant
            + pageControlHeight

        return CGSize(width: width, height: height)
    }
    
    func suitableWidth(forHeight height: CGFloat) -> CGFloat {
        guard let menuPageViewController = menuPageViewController else {
            return 0.0
        }
        
        let menuPageViewControllerHorizontalPadding = menuViewLeadingConstraint.constant + menuViewTrailingConstraint.constant

        let pageControlHeight = pageControl.bounds.height
            + pageControlBottomConstraint.constant
        
        let mediaCollectionViewHeight = mediaCollectionView.bounds.height
            + mediaCollectionViewBottomConstraint.constant
            + mediaCollectionViewTopConstraint.constant
        
        let menuPageViewHeight = SafeArea().height
            - mediaCollectionViewHeight
            - menuViewBottomConstraint.constant
            - pageControlHeight

        let menusWidth = menuPageViewController.totalRequiredWidth(forAvailableHeight: menuPageViewHeight,
                                                                   horizontalPaddding: menuPageViewControllerHorizontalPadding)
        
        return menusWidth + menuViewLeadingConstraint.constant + menuViewTrailingConstraint.constant
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { context in            
            UIView.animate(withDuration: context.transitionDuration) {
                self.updateContentViewConstraints()
                self.view.layoutIfNeeded()
                self.mediaCollectionView.reloadData()
            }
        })
    }
    
    func setUpMenuPageViewController() {
        menuPageViewController = AddToChatMenuPageViewController(transitionStyle: .scroll,
                                                                 navigationOrientation: .horizontal,
                                                                 options: nil)
        if let menuPageViewController = menuPageViewController {
            menuPageViewController.menuDelegate = self
            addChild(menuPageViewController)
            menuView.wrap(menuPageViewController.view)
            menuPageViewController.didMove(toParent: self)
        }
    }
    
    private func updateContentViewConstraints() {
        if !UIDevice.current.iPadDevice && (UIScreen.main.bounds.width > UIScreen.main.bounds.height) {
            let safeArea = SafeArea()
            let contentViewPadding = (safeArea.width - suitableWidth(forHeight: safeArea.height)) / 2.0
            self.contentViewLeadingConstraint.constant = contentViewPadding
            self.contentViewTrailingConstraint.constant = -contentViewPadding
        } else if !UIDevice.current.iPadDevice && (UIScreen.main.bounds.width < UIScreen.main.bounds.height) {
            self.contentViewLeadingConstraint.constant = 0
            self.contentViewTrailingConstraint.constant = 0
        }
    }
    
    private func dismiss(completionBlock: (() -> Void)? = nil) {
        dismiss(animated: true) { [weak self] in 
            self?.dismissHandler?()
            completionBlock?()
        }
    }
    
    private func updateAppearance() {
        contentView.backgroundColor = TokenColors.Background.page
        view.backgroundColor = UIDevice.current.iPadDevice ? contentView.backgroundColor : .clear
        patchView.backgroundColor = TokenColors.Background.page
        pageControl.pageIndicatorTintColor = .mnz_tertiaryGray(for: traitCollection)
        pageControl.currentPageIndicatorTintColor = .mnz_primaryGray()
    }
    
    // MARK: - Actions.

    @IBAction func backgroundViewTapped(_ tapGesture: UITapGestureRecognizer) {
        dismiss()
    }
    
    @IBAction func pageControlValueChanged(_ sender: UIPageControl) {
        menuPageViewController?.moveToPageAtIndex(sender.currentPage)
    }
    
    private func loadPhotosViewAndDismiss() {
        dismiss {
            self.addToChatDelegate?.loadPhotosView()
        }
    }
}

extension AddToChatViewController: AddToChatMediaCollectionSourceDelegate {
    func moreButtonTapped() {
        loadPhotosViewAndDismiss()
    }
    
    func sendAsset(asset: PHAsset) {
        if let delegate = addToChatDelegate {
            delegate.send(asset: asset)
        }
        
        dismiss()
    }
    
    func showCamera() {
        dismiss {
            self.addToChatDelegate?.showCamera()
        }
    }
}

extension AddToChatViewController: AddToChatMenuPageViewControllerDelegate {
    func showGiphy() {
        dismiss {
            self.addToChatDelegate?.showGiphy()
        }
    }
    
    func loadPhotosView() {
        loadPhotosViewAndDismiss()
    }
    
    func showCloudDrive() {
        dismiss {
            self.addToChatDelegate?.showCloudDrive()
        }
    }
    
    func showScanDoc() {
        dismiss {
            self.addToChatDelegate?.showScanDoc()
        }
    }
    
    func showVoiceClip() {
        guard let delegate = addToChatDelegate else {
            return
        }
        
        guard delegate.canRecordAudio else {
            delegate.requestOrInformAudioPermissions()
            return
        }
        
        guard !delegate.existsActiveCall else {
            delegate.presentActiveCall()
            return
        }
        
        dismiss {
            self.addToChatDelegate?.showVoiceClip()
        }
    }
    
    func showContacts() {
        dismiss {
            self.addToChatDelegate?.showContacts()
        }
    }
    
    func showLocation() {
        dismiss {
            self.addToChatDelegate?.showLocation()
        }
    }
    
    func showFilesApp() {
        dismiss {
            self.addToChatDelegate?.showFilesApp()
        }
    }
    
    func numberOfPages(_ pages: Int) {
        pageControl.numberOfPages = pages
    }
    
    func currentSelectedPageIndex(_ pageIndex: Int) {
        pageControl.currentPage = pageIndex
    }
}

private struct SafeArea {
    let width: CGFloat
    let height: CGFloat
    
    init() {
        let safeAreaInsets: UIEdgeInsets = UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
        self.width = UIScreen.main.bounds.width - (safeAreaInsets.left + safeAreaInsets.right)
        self.height = UIScreen.main.bounds.height - (safeAreaInsets.top + safeAreaInsets.bottom)
    }
}
