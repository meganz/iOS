import Accounts
import Combine
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASwiftUI
import UIKit

@objc class ProfileViewController: UIViewController, MEGAPurchasePricingDelegate {
    
    @IBOutlet weak var nameLabel: MEGALabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var avatarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarBottomSeparatorView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    private var avatarExpandedPosition: CGFloat = 0.0
    private var avatarCollapsedPosition: CGFloat = 0.0
    
    @PreferenceWrapper(key: .offlineLogOutWarningDismissed, defaultValue: false)
    private var offlineLogOutWarningDismissed: Bool
    @PreferenceWrapper(key: .isSaveMediaCapturedToGalleryEnabled, defaultValue: false, useCase: PreferenceUseCase.default)
    private var isSaveMediaCapturedToGalleryEnabled: Bool
    
    private let permissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler()
    private var dataSource: ProfileTableViewDataSource?
    private var subscriptions: Set<AnyCancellable> = []
    private let viewModel: ProfileViewModel
    
    // MARK: - Lifecycle
    
    init?(coder: NSCoder, viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("You must create ProfileViewController with a viewModel.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.dispatch(.onViewDidLoad)
        
        fd_prefersNavigationBarHidden = true
        avatarExpandedPosition = view.frame.size.height * 0.5
        avatarCollapsedPosition = view.frame.size.height * 0.3
        avatarViewHeightConstraint.constant = avatarCollapsedPosition
        
        nameLabel.text = MEGASdk.currentUserHandle().map { MEGAUser.mnz_fullName($0.uint64Value) ?? "" }
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        nameLabel.layer.shadowColor = TokenColors.Background.blur.cgColor
        nameLabel.layer.shadowRadius = 2.0
        nameLabel.layer.shadowOpacity = 1
        
        emailLabel.text = MEGASdk.shared.myEmail
        emailLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        emailLabel.layer.shadowColor = TokenColors.Background.blur.cgColor
        emailLabel.layer.shadowRadius = 2.0
        emailLabel.layer.shadowOpacity = 1
        
        avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? ~0)
        configureGestures()
        
        MEGASdk.shared.add(self)
        MEGAPurchase.sharedInstance()?.pricingsDelegateMutableArray.add(self)
        
        setupColors()
        
        $offlineLogOutWarningDismissed.useCase = PreferenceUseCase.default
        
        dataSource = ProfileTableViewDataSource(
            tableView: tableView,
            parent: self,
            traitCollection: traitCollection
        )
        
        registerCustomCells()
        
        dataSource?.configureDataSource()
        bindToSubscriptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if presentedViewController == nil {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        if isMovingFromParent {
            MEGASdk.shared.remove(self)
            MEGAPurchase.sharedInstance()?.pricingsDelegateMutableArray.remove(self)
        }
    }
    
    @objc func registerCustomCells() {
        self.tableView?.register(
            HostingTableViewCell<CancelSubscriptionView>.self,
            forCellReuseIdentifier: "CancelSubscriptionView"
        )
    }
    
    private func bindToSubscriptions() {
        
        NotificationCenter.default
            .publisher(for: Notification.Name.MEGAEmailHasChanged)
            .map { _ in  MEGASdk.shared.myEmail }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak emailLabel] in emailLabel?.text = $0 }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .refreshAccountDetails)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &subscriptions)
        
        viewModel
            .invokeCommand = { [weak self] in self?.executeCommand($0) }
        
        viewModel
            .sectionCellsPublisher
            .sink { [weak self] sectionCellDataSource in
                self?.dataSource?.updateData(changes: sectionCellDataSource.sectionRows, keys: sectionCellDataSource.sectionOrder)
            }
            .store(in: &subscriptions)
    }
    
    func executeCommand(_ command: ProfileViewModel.Command) {
        switch command {
        case let .changeProfile(changeType, isTwoFactorAuthenticationEnabled):
            presentChangeViewController(changeType: changeType, isTwoFactorAuthenticationEnabled: isTwoFactorAuthenticationEnabled)
        }
    }
    
    // MARK: - MEGAPurchasePricingDelegate
    func pricingsReady() {
        tableView.reloadData()
    }
    
    // MARK: - Private
    
    private func setupColors() {
        let separatorColor = TokenColors.Border.strong
        
        tableView.backgroundColor = TokenColors.Background.page
        tableView.separatorColor = separatorColor
        
        nameLabel.textColor = TokenColors.Text.onColor
        emailLabel.textColor = TokenColors.Text.onColor
        avatarBottomSeparatorView.backgroundColor = separatorColor
    }
    
    private func configureGestures() {
        let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: MEGASdk.currentUserHandle()?.uint64Value ??  ~0) ?? "")
        
        if FileManager.default.fileExists(atPath: avatarFilePath) {
            let panAvatar = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
            avatarImageView.addGestureRecognizer(panAvatar)
            guard let enumerated = avatarImageView.gestureRecognizers?.enumerated() else {
                return
            }
            for (_, value) in enumerated where value.isKind(of: UIPanGestureRecognizer.self) {
                guard let popGestureRecognized = navigationController?.interactivePopGestureRecognizer else {
                    return
                }
                value.require(toFail: popGestureRecognized)
            }
        }
    }
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: avatarImageView)
        if recognizer.state == .changed {
            if translation.y < 0 && avatarViewHeightConstraint.constant > avatarCollapsedPosition {
                avatarViewHeightConstraint.constant += translation.y
            }
            
            if translation.y > 0 && avatarViewHeightConstraint.constant < avatarExpandedPosition {
                avatarViewHeightConstraint.constant += translation.y
            }
            
            let alpha = (avatarViewHeightConstraint.constant - avatarExpandedPosition) / (avatarCollapsedPosition - avatarExpandedPosition)
            gradientView.alpha = alpha
            
            recognizer.setTranslation(CGPoint(x: 0, y: 0), in: avatarImageView)
        }
        
        if recognizer.state == .ended {
            let velocity = recognizer.velocity(in: avatarImageView)
            if velocity.y != 0 {
                if velocity.y < 0 && avatarViewHeightConstraint.constant > avatarCollapsedPosition {
                    collapseAvatarView()
                } else if velocity.y > 0 && avatarViewHeightConstraint.constant < avatarExpandedPosition {
                    expandAvatarView()
                }
            } else {
                let height = avatarViewHeightConstraint.constant - avatarExpandedPosition
                let position = avatarCollapsedPosition - avatarExpandedPosition
                
                if (height / position) > 0.5 {
                    collapseAvatarView()
                } else {
                    expandAvatarView()
                }
            }
        }
    }
    
    private func collapseAvatarView() {
        UIView.animate(withDuration: 0.3) {
            self.avatarViewHeightConstraint.constant = self.avatarCollapsedPosition
            self.gradientView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    private func expandAvatarView() {
        UIView.animate(withDuration: 0.3) {
            self.avatarViewHeightConstraint.constant = self.avatarExpandedPosition
            self.gradientView.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard let imagePickerController = MEGAImagePickerController.init(toChangeAvatarWith: sourceType) else {
            return
        }
        
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    private var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: permissionHandler)
    }
    
    private func presentChangeAvatarController(tableView: UITableView, cell: UITableViewCell) {
        let changeAvatarAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        changeAvatarAlertController.addAction(UIAlertAction.init(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        
        let fromPhotosAlertAction = UIAlertAction.init(title: Strings.Localizable.choosePhotoVideo, style: .default) {[weak self] _ in
            guard let self else { return }
            permissionHandler.photosPermissionWithCompletionHandler {[weak self] granted in
                guard let self else { return }
                if granted {
                    showImagePicker(sourceType: .photoLibrary)
                } else {
                    permissionRouter.alertPhotosPermission()
                }
            }
        }
        changeAvatarAlertController.addAction(fromPhotosAlertAction)
        
        let captureAlertAction = UIAlertAction.init(title: Strings.Localizable.capturePhotoVideo, style: .default) {[weak self] _ in
            guard let self else { return }
            permissionHandler.requestVideoPermission {[weak self] granted in
                guard let self else { return }
                if granted {
                    permissionHandler.photosPermissionWithCompletionHandler {[weak self] photoPermisisonGranted in
                        guard let self else { return }
                        // we show the camera screen regardless of value `photoPermisisonGranted`
                        // if we do not have photos access we will not be able
                        // to save the photo we make or browse existing images
                        // from within camera capture screen?
                        if !photoPermisisonGranted {
                            isSaveMediaCapturedToGalleryEnabled = false
                        }
                        self.showImagePicker(sourceType: .camera)
                    }
                } else {
                    permissionRouter.alertVideoPermission()
                }
            }
        }
        changeAvatarAlertController.addAction(captureAlertAction)
        
        changeAvatarAlertController.modalPresentationStyle = .popover
        changeAvatarAlertController.popoverPresentationController?.sourceRect = cell.frame
        changeAvatarAlertController.popoverPresentationController?.sourceView = tableView
        
        let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? ~0) ?? "")
        
        if FileManager.default.fileExists(atPath: avatarFilePath) {
            let removeAvatarAlertAction = UIAlertAction.init(title: Strings.Localizable.removePhoto, style: .default) { _ in
                MEGASdk.shared.setAvatarUserWithSourceFilePath(nil)
            }
            changeAvatarAlertController.addAction(removeAvatarAlertAction)
        }
        
        self.present(changeAvatarAlertController, animated: true, completion: nil)
    }
    
    func presentChangeViewController(changeType: ChangeType, isTwoFactorAuthenticationEnabled: Bool) {
        let changePasswordViewController = UIStoryboard.init(name: "ChangeCredentials", bundle: nil).instantiateViewController(withIdentifier: "ChangePasswordViewControllerID") as! ChangePasswordViewController
        changePasswordViewController.changeType = changeType
        changePasswordViewController.isTwoFactorAuthenticationEnabled = isTwoFactorAuthenticationEnabled
        
        let navigationController = MEGANavigationController.init(rootViewController: changePasswordViewController)
        navigationController.addLeftDismissButton(withText: Strings.Localizable.cancel)
        present(navigationController, animated: true, completion: nil)
    }
    
    func showAddPhoneNumber() {
        AddPhoneNumberRouter(hideDontShowAgain: true, presenter: self).start()
    }
    
    private func showPhoneNumberView() {
        let phoneNumberController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "PhoneNumberViewControllerID")
        let navigation = MEGANavigationController(rootViewController: phoneNumberController)
        navigation.addRightCancelButton()
        present(navigation, animated: true, completion: nil)
    }
    
    // MARK: - IBActions
    
    @IBAction func backTouchUpInside(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDelegate

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard let item = dataSource?.item(at: indexPath) else {
            return
        }
        
        switch item {
        case .changeName:
            let changeNameNavigationController = UIStoryboard.init(name: "ChangeName", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameNavigationControllerID")
            navigationController?.present(changeNameNavigationController, animated: true)
        case .changePhoto:
            guard let cell = tableView.cellForRow(at: indexPath) else {
                return
            }
            presentChangeAvatarController(tableView: tableView, cell: cell)
        case .changeEmail:
            viewModel.dispatch(.changeEmail)
        case .phoneNumber:
            if MEGASdk.shared.smsVerifiedPhoneNumber() == nil {
                showAddPhoneNumber()
            } else {
                showPhoneNumberView()
            }
        case .changePassword:
            viewModel.dispatch(.changePassword)
        case .recoveryKey:
            viewModel.dispatch(.didTapBackUpRecoveryKey)
            let recoveryKeyViewController = UIStoryboard.init(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "MasterKeyViewControllerID")
            navigationController?.pushViewController(recoveryKeyViewController, animated: true)
        case .upgrade, .role:
            if !MEGASdk.shared.isAccountType(.business) &&
                !MEGASdk.shared.isAccountType(.proFlexi) {
                guard let navigationController = navigationController else {
                    return
                }
                UpgradeAccountRouter().pushUpgradeTVC(navigationController: navigationController)
            }
        case .logout:
            viewModel.dispatch(.didTapLogout)
            if MEGAReachabilityManager.isReachableHUDIfNot() {
                guard let showPasswordReminderDelegate = MEGAShowPasswordReminderRequestDelegate(toLogout: true) else {
                    return
                }
                MEGASdk.shared.shouldShowPasswordReminderDialog(atLogout: true, delegate: showPasswordReminderDelegate)
                offlineLogOutWarningDismissed = false
            }
            
        case .cancelSubscription:
            viewModel.dispatch(.cancelSubscription)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        configureTableViewHeaderStyleWithSentenceCase(view, forSection: section)
    }
    
    private func configureTableViewHeaderStyleWithSentenceCase(_ view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView else { return }
        
        tableViewHeaderFooterView.textLabel?.text = titleForHeader(in: section)
        tableViewHeaderFooterView.textLabel?.textColor = TokenColors.Text.secondary
    }
    
    private func titleForHeader(in section: Int) -> String? {
        switch viewModel.sectionCells.sectionOrder[section] {
        case .security:
            return Strings.Localizable.recoveryKey
        case .plan:
            return Strings.Localizable.plan
        case .profile, .session, .subscription:
            return nil
        }
    }
}

// MARK: - MEGARequestDelegate

extension ProfileViewController: MEGARequestDelegate {
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard let myUser = api.myUser else {
            if request.type == .MEGARequestTypeLogout {
                api.removeMEGARequestDelegateAsync(self)
            }
            return
        }
        switch request.type {
        case .MEGARequestTypeGetAttrUser:
            if error.type != .apiOk {
                return
            }
            
            if request.file != nil {
                avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            }
            
            let paramType = MEGAUserAttribute(rawValue: request.paramType)
            if paramType == .firstname || paramType == .lastname {
                nameLabel.text = myUser.mnz_fullName
            }
            
        case .MEGARequestTypeSetAttrUser:
            let paramType = MEGAUserAttribute(rawValue: request.paramType)
            if paramType == .avatar {
                if error.type != .apiOk {
                    guard let requestString = request.requestString else {
                        SVProgressHUD.showError(withStatus: Strings.localized(error.name, comment: ""))
                        return
                    }
                    SVProgressHUD.showError(withStatus: requestString + " " + Strings.localized(error.name, comment: ""))
                    return
                }
                
                let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: myUser.handle) ?? "")
                if request.file == nil {
                    FileManager.default.mnz_removeItem(atPath: avatarFilePath)
                }
                avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            }
            viewModel.dispatch(.invalidateSections)
        case .MEGARequestTypeAccountDetails:
            viewModel.dispatch(.invalidateSections)
            nameLabel.text = myUser.mnz_fullName
            emailLabel.text = api.myEmail
            avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            configureGestures()
            
        case .MEGARequestTypeCheckSMSVerificationCode, .MEGARequestTypeResetSmsVerifiedNumber:
            viewModel.dispatch(.invalidateSections)
        default:
            break
        }
    }
}
