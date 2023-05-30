
import UIKit
import PhoneNumberKit
import MEGAFoundation
import MEGADomain

enum TwoFactorAuthStatus {
    case unknown
    case querying
    case disabled
    case enabled
}

enum ProfileTableViewSection: Int {
    case profile
    case security
    case plan
    case session
}

enum ProfileSectionRow: Int {
    case changeName
    case changePhoto
    case changeEmail
    case phoneNumber
    case changePassword
}

enum SecuritySectionRow: Int {
    case recoveryKey
}

enum PlanSectionRow: Int {
    case upgrade
    case role
}

enum SessionSectionRow: Int {
    case logout
}

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
    
    private var twoFactorAuthStatus:TwoFactorAuthStatus = .unknown
    
    @PreferenceWrapper(key: .offlineLogOutWarningDismissed, defaultValue: false)
    private var offlineLogOutWarningDismissed: Bool
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fd_prefersNavigationBarHidden = true
        avatarExpandedPosition = view.frame.size.height * 0.5
        avatarCollapsedPosition = view.frame.size.height * 0.3
        avatarViewHeightConstraint.constant = avatarCollapsedPosition
        
        nameLabel.text = MEGASdk.currentUserHandle().map { MEGAUser.mnz_fullName($0.uint64Value) }
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        nameLabel.layer.shadowColor = Colors.General.Shadow.blackAlpha20.color.cgColor
        nameLabel.layer.shadowRadius = 2.0
        nameLabel.layer.shadowOpacity = 1
        
        emailLabel.text = MEGASdkManager.sharedMEGASdk().myEmail
        emailLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        emailLabel.layer.shadowColor = Colors.General.Shadow.blackAlpha20.color.cgColor
        emailLabel.layer.shadowRadius = 2.0
        emailLabel.layer.shadowOpacity = 1
        
        avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? ~0)
        configureGestures()
        
        MEGASdkManager.sharedMEGASdk().add(self)
        MEGAPurchase.sharedInstance()?.pricingsDelegateMutableArray.add(self)

        updateAppearance()
        
        $offlineLogOutWarningDismissed.useCase = PreferenceUseCase.default
        
        NotificationCenter.default.addObserver(self, selector: #selector(emailHasChanged), name: Notification.Name.MEGAEmailHasChanged, object: nil)
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
            MEGASdkManager.sharedMEGASdk().remove(self)
            MEGAPurchase.sharedInstance()?.pricingsDelegateMutableArray.remove(self)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - MEGAPurchasePricingDelegate
    func pricingsReady() {
        tableView.reloadData()
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        tableView.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.reloadData()
        
        nameLabel.textColor = UIColor.white
        emailLabel.textColor = UIColor.white
        avatarBottomSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    private func configureGestures() {
        let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: MEGASdk.currentUserHandle()?.uint64Value ??  ~0) ?? "")
        
        if FileManager.default.fileExists(atPath: avatarFilePath) {
            let panAvatar = UIPanGestureRecognizer(target: self, action:#selector(handlePan(recognizer:)))
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
    
    @objc
    private func emailHasChanged() {
        emailLabel.text = MEGASdkManager.sharedMEGASdk().myEmail
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
    
    private func presentChangeAvatarController(tableView: UITableView, cell: UITableViewCell) {
        let changeAvatarAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        changeAvatarAlertController.addAction(UIAlertAction.init(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        
        let fromPhotosAlertAction = UIAlertAction.init(title: Strings.Localizable.choosePhotoVideo, style: .default) { _ in
            DevicePermissionsHelper.photosPermission(completionHandler: { (granted) in
                if granted {
                    self.showImagePicker(sourceType: .photoLibrary)
                } else {
                    DevicePermissionsHelper.alertPhotosPermission()
                }
            })
        }
        changeAvatarAlertController.addAction(fromPhotosAlertAction)
        
        let captureAlertAction = UIAlertAction.init(title: Strings.Localizable.capturePhotoVideo, style: .default) { _ in
            DevicePermissionsHelper.videoPermission(completionHandler: { (granted) in
                if granted {
                    DevicePermissionsHelper.photosPermission(completionHandler: { (granted) in
                        if granted {
                            self.showImagePicker(sourceType: .camera)
                        } else {
                            UserDefaults.standard.set(true, forKey: "isSaveMediaCapturedToGalleryEnabled")
                            UserDefaults.standard.synchronize()
                            self.showImagePicker(sourceType: .camera)
                        }
                    })
                } else {
                    DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
                }
            })
        }
        changeAvatarAlertController.addAction(captureAlertAction)
        
        changeAvatarAlertController.modalPresentationStyle = .popover
        changeAvatarAlertController.popoverPresentationController?.sourceRect = cell.frame
        changeAvatarAlertController.popoverPresentationController?.sourceView = tableView
        
        let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: MEGASdk.currentUserHandle()?.uint64Value ?? ~0) ?? "")
        
        if FileManager.default.fileExists(atPath: avatarFilePath) {
            let removeAvatarAlertAction = UIAlertAction.init(title: Strings.Localizable.removePhoto, style: .default) { _ in
                MEGASdkManager.sharedMEGASdk().setAvatarUserWithSourceFilePath(nil)
            }
            changeAvatarAlertController.addAction(removeAvatarAlertAction)
        }
        
        self.present(changeAvatarAlertController, animated: true, completion: nil)
    }
    
    func tableViewSections() -> [ProfileTableViewSection] {
        return [.profile, .security, .plan, .session]
    }
    
    func rowsForProfileSection() -> [ProfileSectionRow] {
        let isBusiness = MEGASdkManager.sharedMEGASdk().isAccountType(.business)
        let isMasterBusiness = MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount
        let isSmsAllowed = MEGASdkManager.sharedMEGASdk().smsAllowedState() == .optInAndUnblock
        var profileRows = [ProfileSectionRow]()
        
        if !isBusiness || isMasterBusiness {
            profileRows.append(.changeName)
        }
        profileRows.append(.changePhoto)
        if !isBusiness || isMasterBusiness {
            profileRows.append(.changeEmail)
        }
        profileRows.append(.changePassword)
        if isSmsAllowed {
            profileRows.append(.phoneNumber)
        }
        return profileRows
    }
    
    func rowsForSecuritySection() -> [SecuritySectionRow] {
        return [.recoveryKey]
    }
    
    func rowsForPlanSection() -> [PlanSectionRow] {
        if MEGASdkManager.sharedMEGASdk().isAccountType(.business) {
            return [.upgrade, .role]
        } else {
            return [.upgrade]
        }
    }
    
    func rowsForSessionSection() -> [SessionSectionRow] {
        return [.logout]
    }
    
    func presentChangeViewController(changeType: ChangeType, indexPath: IndexPath) {
        let changePasswordViewController = UIStoryboard.init(name: "ChangeCredentials", bundle: nil).instantiateViewController(withIdentifier: "ChangePasswordViewControllerID") as! ChangePasswordViewController
        changePasswordViewController.changeType = changeType
        if changeType == .email || changeType == .password {
            switch twoFactorAuthStatus {
            case .unknown:
                guard let myEmail = MEGASdkManager.sharedMEGASdk().myEmail else {
                    return
                }
                
                MEGASdkManager.sharedMEGASdk().multiFactorAuthCheck(withEmail: myEmail, delegate: MEGAGenericRequestDelegate(completion: { (request, _) in
                    self.twoFactorAuthStatus = request.flag ? .enabled : .disabled
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                    changePasswordViewController.isTwoFactorAuthenticationEnabled = request.flag
                    let navigationController = MEGANavigationController.init(rootViewController: changePasswordViewController)
                    navigationController.addLeftDismissButton(withText: Strings.Localizable.cancel)
                    
                    self.present(navigationController, animated: true, completion: nil)
                }))
                twoFactorAuthStatus = .querying
                tableView.reloadRows(at: [indexPath], with: .none)
            case .querying:
                return
            case .disabled, .enabled:
                changePasswordViewController.isTwoFactorAuthenticationEnabled = self.twoFactorAuthStatus == .enabled
                let navigationController = MEGANavigationController.init(rootViewController: changePasswordViewController)
                navigationController.addLeftDismissButton(withText: Strings.Localizable.cancel)
                
                present(navigationController, animated: true, completion: nil)
            }
        } else {
            let navigationController = MEGANavigationController.init(rootViewController: changePasswordViewController)
            navigationController.addLeftDismissButton(withText: Strings.Localizable.cancel)
            
            present(navigationController, animated: true, completion: nil)
        }
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
    
    func expiryDateFormatterOfProfessionalAccountExpiryDate(_ expiryDate: Date) -> DateFormatting {
        let calendar = Calendar.current
        let startingOfToday = Date().startOfDay(on: calendar)
        guard let daysOfDistance = startingOfToday?.dayDistance(toFutureDate: expiryDate,
                                                                on: Calendar.current) else {
                                                                    return DateFormatter.dateMedium()
        }
        let numberOfDaysAWeek = 7
        if daysOfDistance > numberOfDaysAWeek  {
            return DateFormatter.dateMedium()
        }

        if expiryDate.isToday(on: calendar) || expiryDate.isTomorrow(on: calendar) {
            return DateFormatter.dateRelativeMedium()
        }

        return DateFormatter.dateMediumWithWeekday()
    }
    
    func updateCellInRelationWithTwoFactorStatus(cell: ProfileTableViewCell) {
        switch twoFactorAuthStatus {
        case .unknown, .disabled, .enabled:
            cell.nameLabel?.isEnabled = true
            cell.accessoryView = nil
        case .querying:
            cell.nameLabel?.isEnabled = false
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            cell.accessoryView = activityIndicator
        }
    }

    // MARK: - IBActions
    
    @IBAction func backTouchUpInside(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - UITableViewDataSource

extension ProfileViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewSections().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableViewSections()[section] {
        case .profile:
            return rowsForProfileSection().count
        case .security:
            return rowsForSecuritySection().count
        case .plan:
            return rowsForPlanSection().count
        case .session:
            return rowsForSessionSection().count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableViewSections()[section] {
        case .security:
            return Strings.Localizable.recoveryKey
        case .plan:
            return Strings.Localizable.plan
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch tableViewSections()[section] {
        case .security:
            return Strings.Localizable.ifYouLoseThisRecoveryKeyAndForgetYourPasswordBAllYourFilesFoldersAndMessagesWillBeInaccessibleEvenByMEGAB.replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "")
        case .plan:
            guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
                return nil
            }
            var planFooterString = ""

            if accountDetails.type != .free {
                if accountDetails.subscriptionRenewTime > 0 {
                    let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.subscriptionRenewTime))
                    planFooterString = Strings.Localizable.renewsOn + " " + expiryDateFormatterOfProfessionalAccountExpiryDate(renewDate).localisedString(from: renewDate)
                } else if accountDetails.proExpiration > 0 && accountDetails.type != .business {
                    let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.proExpiration))
                    planFooterString = Strings.Localizable.expiresOn(expiryDateFormatterOfProfessionalAccountExpiryDate(renewDate).localisedString(from: renewDate))
                }
            }
            return planFooterString
        case .session:
            if FileManager.default.mnz_existsOfflineFiles() && MEGASdkManager.sharedMEGASdk().transfers.size != 0 {
                return Strings.Localizable.whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDeviceAndOngoingTransfersWillBeCancelled
            } else if FileManager.default.mnz_existsOfflineFiles() {
                return Strings.Localizable.whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDevice
            } else if MEGASdkManager.sharedMEGASdk().transfers.size != 0 {
                return Strings.Localizable.whenYouLogoutOngoingTransfersWillBeCancelled
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableViewSections()[indexPath.section] {
        case .profile:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.detailLabel.text = ""
            switch rowsForProfileSection()[indexPath.row] {
            case .changeName:
                cell.nameLabel.text = Strings.Localizable.changeName
            case .changePhoto:
                cell.nameLabel.text = Strings.Localizable.Account.Profile.Avatar.uploadPhoto
            case .changeEmail:
                updateCellInRelationWithTwoFactorStatus(cell: cell)
                cell.nameLabel.text = Strings.Localizable.changeEmail
            case .phoneNumber:
                if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() == nil {
                    cell.nameLabel.text = Strings.Localizable.addPhoneNumber
                } else {
                    cell.nameLabel.text = Strings.Localizable.phoneNumber
                    let phoneNumber = MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber()
                    do {
                        let phone = try PhoneNumberKit().parse(phoneNumber ?? "")
                        cell.detailLabel.text = PhoneNumberKit().format(phone, toType: .international)
                    } catch {
                        cell.detailLabel.text = phoneNumber
                    }
                    cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
                }
            case .changePassword:
                updateCellInRelationWithTwoFactorStatus(cell: cell)
                cell.nameLabel.text = Strings.Localizable.changePasswordLabel
            }
            return cell
        case .security:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecoveryKeyID", for: indexPath) as! RecoveryKeyTableViewCell
            cell.recoveryKeyContainerView.backgroundColor = UIColor.mnz_tertiaryBackgroundGrouped(traitCollection)
            cell.recoveryKeyLabel.text = Strings.Localizable.General.Security.recoveryKeyFile
            cell.backupRecoveryKeyLabel.text = Strings.Localizable.backupRecoveryKey
            cell.backupRecoveryKeyLabel.textColor = UIColor.mnz_turquoise(for: traitCollection)
            return cell
        case .plan:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.nameLabel.text = Strings.Localizable.upgradeAccount
            cell.selectionStyle = .default
            cell.accessoryType = MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0 ? .disclosureIndicator : .none

            guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
                return cell
            }
            let accountType = accountDetails.type
            
            switch rowsForPlanSection()[indexPath.row] {
            case .upgrade:
                switch accountType {
                case .free:
                    cell.detailLabel.text = Strings.Localizable.free
                    cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
                case .proI:
                    cell.detailLabel.text = "Pro I"
                    cell.detailLabel.textColor = UIColor.mnz_redProI()
                case .proII:
                    cell.detailLabel.text = "Pro II"
                    cell.detailLabel.textColor = UIColor.mnz_redProII()
                case .proIII:
                    cell.detailLabel.text = "Pro III"
                    cell.detailLabel.textColor = UIColor.mnz_redProIII()
                case .lite:
                    cell.detailLabel.text = Strings.Localizable.proLite
                    cell.detailLabel.textColor = UIColor.systemOrange
                case .business:
                    if MEGASdkManager.sharedMEGASdk().businessStatus == .active {
                        cell.detailLabel.text = Strings.Localizable.active
                    } else {
                        cell.detailLabel.text = Strings.Localizable.paymentOverdue
                    }
                    cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
                    cell.nameLabel.text = Strings.Localizable.business
                    cell.accessoryType = .none
                case .proFlexi:
                    cell.nameLabel.text = MEGAAccountDetails.string(for: accountType)
                    cell.selectionStyle = .none
                    cell.accessoryType = .none
                default:
                    cell.detailLabel.text = "..."
                }
            case .role:
                if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                    cell.detailLabel.text = Strings.Localizable.administrator
                } else {
                    cell.detailLabel.text = Strings.Localizable.user
                }
                cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
                cell.nameLabel.text = Strings.Localizable.role.replacingOccurrences(of: ":", with: "")
                cell.accessoryType = .none
            }
            return cell
        case .session:
            switch rowsForSessionSection()[indexPath.row] {
            case .logout:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutID", for: indexPath) as! LogoutTableViewCell
                cell.logoutLabel.text = Strings.Localizable.logoutLabel
                cell.logoutLabel.textColor = UIColor.mnz_red(for: traitCollection)
                return cell
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.mnz_secondaryBackgroundGrouped(traitCollection)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableViewSections()[indexPath.section] {
        case .profile:
            switch rowsForProfileSection()[indexPath.row] {
            case .changeName:
                let changeNameNavigationController = UIStoryboard.init(name: "ChangeName", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameNavigationControllerID")
                navigationController?.present(changeNameNavigationController, animated: true)
            case .changePhoto:
                guard let cell = tableView.cellForRow(at: indexPath) else {
                    return
                }
                presentChangeAvatarController(tableView:tableView, cell: cell)
            case .changeEmail:
                presentChangeViewController(changeType: .email, indexPath: indexPath)
            case .phoneNumber:
                if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() == nil {
                    showAddPhoneNumber()
                } else {
                    showPhoneNumberView()
                }
            case .changePassword:
                presentChangeViewController(changeType: .password, indexPath: indexPath)
            }
        case .security:
            switch rowsForSecuritySection()[indexPath.row] {
            case .recoveryKey:
                let recoveryKeyViewController = UIStoryboard.init(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "MasterKeyViewControllerID")
                navigationController?.pushViewController(recoveryKeyViewController, animated: true)
            }
        case .plan:
            switch rowsForPlanSection()[indexPath.row] {
            default:
                if !MEGASdkManager.sharedMEGASdk().isAccountType(.business) &&
                    !MEGASdkManager.sharedMEGASdk().isAccountType(.proFlexi) {
                    guard let navigationController = navigationController else {
                        return
                    }
                    UpgradeAccountRouter().pushUpgradeTVC(navigationController: navigationController)
                }
            }
        case .session:
            switch rowsForSessionSection()[indexPath.row] {
            case .logout:
                if MEGAReachabilityManager.isReachableHUDIfNot() {
                    guard let showPasswordReminderDelegate = MEGAShowPasswordReminderRequestDelegate(toLogout: true) else {
                        return
                    }
                    MEGASdkManager.sharedMEGASdk().shouldShowPasswordReminderDialog(atLogout: true, delegate: showPasswordReminderDelegate)
                    offlineLogOutWarningDismissed = false
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - MEGARequestDelegate

extension ProfileViewController: MEGARequestDelegate {
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard let myUser = api.myUser else {
            if request.type == .MEGARequestTypeLogout {
                api.remove(self)
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
                    SVProgressHUD.showError(withStatus: request.requestString + " " + NSLocalizedString(error.name, comment: ""))
                    return
                }
                
                let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: myUser.handle) ?? "")
                if request.file == nil {
                    FileManager.default.mnz_removeItem(atPath: avatarFilePath)
                }
                avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            }
        
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
        case .MEGARequestTypeAccountDetails:
            tableView.reloadData()
            nameLabel.text = myUser.mnz_fullName
            emailLabel.text = api.myEmail
            avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            configureGestures()
            
        case .MEGARequestTypeCheckSMSVerificationCode, .MEGARequestTypeResetSmsVerifiedNumber:
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
        default:
            break
        }
    }
}
