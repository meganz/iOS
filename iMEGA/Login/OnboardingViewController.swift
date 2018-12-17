
import UIKit

@objc enum OnboardingViewControllerType: Int {
    case onboarding
    case permissions
}

class OnboardingViewController: UIViewController, UIScrollViewDelegate {
    
    @objc var type = OnboardingViewControllerType.onboarding
    @objc var completion: (() -> Void)?

    private let scrollView: UIScrollView = {
        let view = UIScrollView.newAutoLayout()
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    private let pageControl: UIPageControl = {
        let control = UIPageControl.newAutoLayout()
        control.pageIndicatorTintColor = UIColor.mnz_grayD8D8D8()
        return control
    }()
    private let primaryButton: UIButton = {
        let button = UIButton.newAutoLayout()
        button.layer.cornerRadius = 8
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.mnz_SFUISemiBold(withSize: 17)
        return button
    }()
    private let secondaryButton: UIButton = {
        let button = UIButton.newAutoLayout()
        button.titleLabel?.font = UIFont.mnz_SFUISemiBold(withSize: 17)
        return button
    }()
    
    private let contentView = UIView.newAutoLayout()
    
    private var didSetupConstraints = false
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    
    
    // MARK: Lifecycle
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor.white
        
        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(primaryButton)
        view.addSubview(secondaryButton)
        
        scrollView.addSubview(contentView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidLoad() {
        switch type {
        case .onboarding:
            pageControl.currentPageIndicatorTintColor = UIColor.mnz_redMain()
            pageControl.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
            
            primaryButton.setTitle("createAccount".localized(withComment: "Button title which triggers the action to create a MEGA account"), for: .normal)
            primaryButton.backgroundColor = UIColor.mnz_redMain()
            
            secondaryButton.setTitle("login".localized(withComment: "Button title which triggers the action to login in your MEGA account"), for: .normal)
            secondaryButton.setTitleColor(UIColor.mnz_redMain(), for: .normal)
            
            contentView.addSubview({
                let view = OnboardingInfoView(type: .encryptionInfo)
                view.configureForAutoLayout()
                return view
                }())
            contentView.addSubview({
                let view = OnboardingInfoView(type: .chatInfo)
                view.configureForAutoLayout()
                return view
                }())
            contentView.addSubview({
                let view = OnboardingInfoView(type: .contactsInfo)
                view.configureForAutoLayout()
                return view
                }())
            contentView.addSubview({
                let view = OnboardingInfoView(type: .cameraUploadsInfo)
                view.configureForAutoLayout()
                return view
                }())
            
        case .permissions:
            scrollView.isUserInteractionEnabled = false;
            
            pageControl.currentPageIndicatorTintColor = UIColor.mnz_green00BFA5()
            pageControl.isUserInteractionEnabled = false;

            primaryButton.setTitle("Allow Access".localized(withComment: "Button which triggers a request for a specific permission, that have been explained to the user beforehand"), for: .normal)
            primaryButton.backgroundColor = UIColor.mnz_green00BFA5()
            
            secondaryButton.setTitle("notNow".localized(), for: .normal)
            secondaryButton.setTitleColor(UIColor.mnz_green899B9C(), for: .normal)
            
            if DevicePermissionsHelper.shouldAskForPhotosPermissions() {
                contentView.addSubview({
                    let view = OnboardingInfoView(type: .photosPermission)
                    view.configureForAutoLayout()
                    return view
                    }())
            }
            if DevicePermissionsHelper.shouldAskForAudioPermissions() || DevicePermissionsHelper.shouldAskForVideoPermissions() {
                contentView.addSubview({
                    let view = OnboardingInfoView(type: .microphoneAndCameraPermissions)
                    view.configureForAutoLayout()
                    return view
                    }())
            }
            if DevicePermissionsHelper.shouldAskForNotificationsPermissions() {
                contentView.addSubview({
                    let view = OnboardingInfoView(type: .notificationsPermission)
                    view.configureForAutoLayout()
                    return view
                    }())
            }
        }
        
        scrollView.delegate = self
        pageControl.numberOfPages = contentView.subviews.count
        primaryButton.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
        secondaryButton.addTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
    }
    
    override func updateViewConstraints() {
        if !didSetupConstraints {
            setupConstraints()
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    
    
    // MARK: Autolayout
    
    private func setupConstraints() {
        let pageControlTopOffset:CGFloat = UIDevice.current.iPhone4X || UIDevice.current.iPhone5X ? -22 : -44
        let pageControlBottomOffset:CGFloat = UIDevice.current.iPhone4X || UIDevice.current.iPhone5X ? -29 : -58
        
        scrollView.autoPinEdge(.top, to: .top, of: view, withOffset: 64)
        scrollView.autoPinEdge(toSuperviewEdge: .left)
        scrollView.autoPinEdge(toSuperviewEdge: .right)
        scrollView.autoPinEdge(.bottom, to: .top, of: pageControl, withOffset: pageControlTopOffset)
        
        pageControl.autoPinEdge(toSuperviewEdge: .left)
        pageControl.autoPinEdge(toSuperviewEdge: .right)
        pageControl.autoPinEdge(.bottom, to: .top, of: primaryButton, withOffset: pageControlBottomOffset)
        pageControl.autoSetDimension(.height, toSize: 44)
        
        primaryButton.autoPinEdge(.left, to: .left, of: view, withOffset: 44)
        primaryButton.autoPinEdge(.right, to: .right, of: view, withOffset: -44)
        primaryButton.autoPinEdge(.bottom, to: .top, of: secondaryButton, withOffset: -16)
        primaryButton.autoSetDimension(.height, toSize: 50)
        
        secondaryButton.autoPinEdge(.left, to: .left, of: view, withOffset: 44)
        secondaryButton.autoPinEdge(.right, to: .right, of: view, withOffset: -44)
        secondaryButton.autoPinEdge(.bottom, to: .bottom, of: view, withOffset: -35)
        secondaryButton.autoSetDimension(.height, toSize: 50)
        
        contentView.autoPinEdgesToSuperviewEdges()
        contentView.autoMatch(.height, to: .height, of: scrollView)
        
        for (index, pageView) in contentView.subviews.enumerated() {
            pageView.autoPinEdge(toSuperviewEdge: .top)
            pageView.autoPinEdge(toSuperviewEdge: .bottom)
            pageView.autoMatch(.width, to: .width, of: scrollView)
            
            if index == 0 {
                pageView.autoPinEdge(toSuperviewEdge: .left)
            }
            
            if index == (contentView.subviews.count - 1) {
                pageView.autoPinEdge(toSuperviewEdge: .right)
            }
            
            if contentView.subviews.count > 1 && index < (contentView.subviews.count - 1) {
                let nextPageView = contentView.subviews[index + 1]
                pageView.autoPinEdge(.right, to: .left, of: nextPageView)
            }
        }
    }
    
    
    
    // MARK: Private
    
    private func scrollTo(page: Int) {
        let newX = CGFloat(page) * scrollView.frame.width;
        scrollView.contentOffset = CGPoint(x: newX, y: 0)
        pageControl.currentPage = page
    }
    
    private func nextPageOrDismiss() {
        let nextPage = self.pageControl.currentPage + 1
        if nextPage < self.pageControl.numberOfPages {
            self.scrollTo(page: nextPage)
        } else {
            self.dismiss(animated: true) {
                self.completion?()
            }
        }
    }
    
    
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let newPage = scrollView.contentOffset.x / scrollView.frame.width
        pageControl.currentPage = Int(newPage)
    }
    
    
    
    // MARK: Targets
    
    @objc func pageControlValueChanged() {
        scrollTo(page: pageControl.currentPage)
    }
    
    @objc func primaryButtonTapped() {
        switch type {
        case .onboarding:
            let createAccountNC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateAccountNavigationControllerID")
            present(createAccountNC, animated: true, completion: nil)

        case .permissions:
            let currentView: OnboardingInfoView = contentView.subviews[pageControl.currentPage] as! OnboardingInfoView
            switch currentView.type {
            case .photosPermission:
                DevicePermissionsHelper.photosPermission { (_) in
                    self.nextPageOrDismiss()
                }
                
            case .microphoneAndCameraPermissions:
                DevicePermissionsHelper.audioPermissionModal(false, forIncomingCall: false) { (_) in
                    DevicePermissionsHelper.videoPermission { (_) in
                        self.nextPageOrDismiss()
                    }
                }
                
            case .notificationsPermission:
                DevicePermissionsHelper.notificationsPermission { (_) in
                    self.nextPageOrDismiss()
                }
                
            default:
                nextPageOrDismiss()
            }
        }
    }
    
    @objc func secondaryButtonTapped() {
        switch type {
        case .onboarding:
            let createAccountNC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginNavigationControllerID")
            present(createAccountNC, animated: true, completion: nil)

        case .permissions:
            nextPageOrDismiss()
        }
    }
    
}
