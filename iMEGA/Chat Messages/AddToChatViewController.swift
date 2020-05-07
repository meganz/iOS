
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
    @IBOutlet weak var menuView: UIView!
    
    var tapHandler: (() -> Void)?
    var dismissHandler: ((AddToChatViewController) -> Void)?
    private var presentAndDismissAnimationDuration: TimeInterval = 0.4
    private var mediaCollectionSource: AddToChatMediaCollectionSource!
    private var menuPageViewController: AddToChatMenuPageViewController!

    weak var delegate: AddToChatViewControllerDelegate?
    
    // MARK:- View lifecycle methods.
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        definesPresentationContext = true
        modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaCollectionSource = AddToChatMediaCollectionSource(collectionView: mediaCollectionView,
                                                               delegate: self)
        setUpMenuPageViewController()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let menuPageViewController = menuPageViewController else {
            return
        }
        
        contentViewHeightConstraint.constant = menuPageViewController.totalRequiredHeight
            + mediaCollectionView.bounds.height
            + mediaCollectionViewBottomConstraint.constant
        view.layoutIfNeeded()
    }
    
    func setUpMenuPageViewController() {
        menuPageViewController = AddToChatMenuPageViewController(transitionStyle: .scroll,
                                                                 navigationOrientation: .horizontal,
                                                                 options: nil)
        menuPageViewController.menuDelegate = self
        addChild(menuPageViewController)
        menuView.addSubview(menuPageViewController.view)
        menuPageViewController.view.autoPinEdgesToSuperviewEdges()
        menuPageViewController.didMove(toParent: self)
    }
    
    // MARK:- Actions.

    @IBAction func backgroundViewTapped(_ tapGesture: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    private func loadPhotosViewAndDismiss() {
        dismiss(animated: true, completion: nil)
        delegate?.loadPhotosView()
    }
}

extension AddToChatViewController: AddToChatMediaCollectionSourceDelegate {
    func moreButtonTapped() {
        loadPhotosViewAndDismiss()
    }
    
    func sendAsset(asset: PHAsset) {
        if let delegate = delegate {
            delegate.send(asset: asset)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func showCamera() {
        dismiss(animated: true, completion: nil)
        delegate?.showCamera()
    }
}

extension AddToChatViewController: AddToChatMenuPageViewControllerDelegate {
    func loadPhotosView() {
        loadPhotosViewAndDismiss()
    }
    
    func showCloudDrive() {
        dismiss(animated: true, completion: nil)
        delegate?.showCloudDrive()
    }
    
    func startVoiceCall() {
        dismiss(animated: true, completion: nil)
        delegate?.startAudioCall()
    }
    
    func startVideoCall() {
        dismiss(animated: true, completion: nil)
        delegate?.startVideoCall()
    }
    
    func showVoiceClip() {
        dismiss(animated: true, completion: nil)
        delegate?.showVoiceClip()
    }
    
    func showContacts() {
        dismiss(animated: true, completion: nil)
        delegate?.showContacts()
    }
    
    func startGroupChat() {
        dismiss(animated: true, completion: nil)
        delegate?.startGroupChat()
    }
    
    func showLocation() {
        dismiss(animated: true, completion: nil)
        delegate?.showLocation()
    }
}

