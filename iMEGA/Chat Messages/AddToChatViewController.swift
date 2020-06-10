
import UIKit

protocol AddToChatViewControllerDelegate: class {
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
    @IBOutlet weak var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var mediaCollectionView: UICollectionView!
    @IBOutlet weak var mediaCollectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var mediaCollectionViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuViewTrailingConstraint: NSLayoutConstraint!

    var dismissHandler: (() -> Void)?
    private var presentAndDismissAnimationDuration: TimeInterval = 0.4
    private var mediaCollectionSource: AddToChatMediaCollectionSource?
    private var menuPageViewController: AddToChatMenuPageViewController?

    weak var addToChatDelegate: AddToChatViewControllerDelegate?
    
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIDevice.current.iPadDevice {
            contentViewHeightConstraint.constant = view.bounds.height
        } else {
            guard let menuPageViewController = menuPageViewController else {
                return
            }
            
            let menuPageViewControllerHorizontalPadding = menuViewLeadingConstraint.constant + menuViewTrailingConstraint.constant
            let menuPageViewControllerHeight = menuPageViewController.totalRequiredHeight(forWidth: view.bounds.width,
                                                                                          horizontalPaddding: menuPageViewControllerHorizontalPadding)

            contentViewHeightConstraint.constant = menuPageViewControllerHeight
                + mediaCollectionView.bounds.height
                + mediaCollectionViewBottomConstraint.constant
                + mediaCollectionViewTopConstraint.constant
                + menuViewBottomConstraint.constant
        }
        
        view.layoutIfNeeded()
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
        dismiss(animated: true) {
            self.dismissHandler?()
            completionBlock?()
        }
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

