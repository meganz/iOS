
import UIKit

protocol AddToChatViewControllerDelegate: AnyObject {
    func send(asset: PHAsset)
    func loadPhotosView()
    func showCamera()
    func showCloudDrive()
    func startAudioCall()
    func startVideoCall()
    func showVoiceClip()
    func showContacts()
    func startGroupChat()
    func showLocation()
    func shouldDisableAudioMenu() -> Bool
    func shouldDisableVideoMenu() -> Bool
    func canRecordAudio() -> Bool
}

class AddToChatViewController: UIViewController {
    
    // MARK:- Properties.
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

    var dismissHandler: (() -> Void)?
    private var presentAndDismissAnimationDuration: TimeInterval = 0.4
    private var mediaCollectionSource: AddToChatMediaCollectionSource?
    private var menuPageViewController: AddToChatMenuPageViewController?

    weak var addToChatDelegate: AddToChatViewControllerDelegate?
    
    private let iPadPopoverWidth: CGFloat = 440.0
    
    // MARK:- View lifecycle methods.
    
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
        
        mediaCollectionSource = AddToChatMediaCollectionSource(collectionView: mediaCollectionView,
                                                               delegate: self)
        setUpMenuPageViewController()
        
        if UIDevice.current.iPadDevice == false {
            contentView.layer.cornerRadius = 13.0
        }
        
        updateAppearance()
        preferredContentSize = requiredSize(forWidth: iPadPopoverWidth)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UIDevice.current.iPadDevice {
            presentationAnimationComplete()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        contentViewHeightConstraint.constant = requiredSize(forWidth: view.bounds.width).height
        view.layoutIfNeeded()
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

        let height = menuPageViewControllerHeight
            + mediaCollectionView.bounds.height
            + mediaCollectionViewBottomConstraint.constant
            + mediaCollectionViewTopConstraint.constant
            + menuViewBottomConstraint.constant

        return CGSize(width: width, height: height)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
        }
    }
    
    func setUpMenuPageViewController() {
        menuPageViewController = AddToChatMenuPageViewController(transitionStyle: .scroll,
                                                                 navigationOrientation: .horizontal,
                                                                 options: nil)
        if let menuPageViewController = menuPageViewController {
            menuPageViewController.menuDelegate = self
            addChild(menuPageViewController)
            menuView.addSubview(menuPageViewController.view)
            menuPageViewController.view.autoPinEdgesToSuperviewEdges()
            menuPageViewController.didMove(toParent: self)
        }
    }
    
    func updateAudioVideoMenu() {
        guard let menuPageViewController = menuPageViewController else {
            return
        }
        
        menuPageViewController.updateAudioVideoMenu()
    }
    
    private func dismiss(completionBlock: (() -> Void)? = nil){
        dismiss(animated: true) { [weak self] in 
            self?.dismissHandler?()
            completionBlock?()
        }
    }
    
    private func updateAppearance() {
        contentView.backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)
        patchView.backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)
    }
    
    // MARK:- Actions.

    @IBAction func backgroundViewTapped(_ tapGesture: UITapGestureRecognizer) {
        dismiss()
    }
    
    private func loadPhotosViewAndDismiss() {
        dismiss() {
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
        dismiss() {
            self.addToChatDelegate?.showCamera()
        }
    }
}

extension AddToChatViewController: AddToChatMenuPageViewControllerDelegate {
    func loadPhotosView() {
        loadPhotosViewAndDismiss()
    }
    
    func showCloudDrive() {
        dismiss() {
            self.addToChatDelegate?.showCloudDrive()
        }
    }
    
    func startVoiceCall() {
        dismiss() {
            self.addToChatDelegate?.startAudioCall()
        }
    }
    
    func startVideoCall() {
        dismiss() {
            self.addToChatDelegate?.startVideoCall()
        }
    }
    
    func showVoiceClip() {
        if let delegate = addToChatDelegate,
            delegate.canRecordAudio() {
            dismiss() {
                self.addToChatDelegate?.showVoiceClip()
            }
        }
    }
    
    func showContacts() {
        dismiss() {
            self.addToChatDelegate?.showContacts()
        }
    }
    
    func startGroupChat() {
        dismiss() {
            self.addToChatDelegate?.startGroupChat()
        }
    }
    
    func showLocation() {
        dismiss() {
            self.addToChatDelegate?.showLocation()
        }
    }
    
    func shouldDisableAudioMenu() -> Bool {
        return addToChatDelegate?.shouldDisableAudioMenu() ?? false
    }
    
    func shouldDisableVideoMenu() -> Bool {
        return addToChatDelegate?.shouldDisableVideoMenu() ?? false
    }
}

