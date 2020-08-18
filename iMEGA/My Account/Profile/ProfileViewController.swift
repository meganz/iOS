
import UIKit

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

@objc class ProfileViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var avatarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarBottomSeparatorView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    private var avatarExpandedPosition: CGFloat = 0.0
    private var avatarCollapsedPosition: CGFloat = 0.0
    
    private var twoFactorAuthStatus:TwoFactorAuthStatus = .unknown
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fd_prefersNavigationBarHidden = true
        avatarExpandedPosition = view.frame.size.height * 0.5
        avatarCollapsedPosition = view.frame.size.height * 0.3
        avatarViewHeightConstraint.constant = avatarCollapsedPosition
        
        nameLabel.text = MEGASdkManager.sharedMEGASdk().myUser?.mnz_fullName
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        nameLabel.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        nameLabel.layer.shadowRadius = 2.0
        nameLabel.layer.shadowOpacity = 1
        
        emailLabel.text = MEGASdkManager.sharedMEGASdk().myEmail
        emailLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        emailLabel.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        emailLabel.layer.shadowRadius = 2.0
        emailLabel.layer.shadowOpacity = 1
        
        avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: MEGASdkManager.sharedMEGASdk().myUser?.handle ?? ~0)
        configureGestures()
        
        MEGASdkManager.sharedMEGASdk().add(self)
        
        updateAppearance()
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
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
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
    
    private func configureGestures() -> Void {
        let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: MEGASdkManager.sharedMEGASdk().myUser?.handle ??  ~0) ?? "")
        
        if FileManager.default.fileExists(atPath: avatarFilePath) {
            let panAvatar = UIPanGestureRecognizer(target: self, action:#selector(handlePan(recognizer:)))
            avatarImageView.addGestureRecognizer(panAvatar)
            guard let enumerated = avatarImageView.gestureRecognizers?.enumerated() else {
                return
            }
            for (_, value) in enumerated {
                if value.isKind(of: UIPanGestureRecognizer.self) {
                    guard let popGestureRecognized = navigationController?.interactivePopGestureRecognizer else {
                        return
                    }
                    value.require(toFail: popGestureRecognized)
                }
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
                if (avatarViewHeightConstraint.constant - avatarExpandedPosition) / (avatarCollapsedPosition - avatarExpandedPosition) > 0.5 {
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
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) -> Void {
        guard let imagePickerController = MEGAImagePickerController.init(toChangeAvatarWith: sourceType) else {
            return            
        }
        
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func presentChangeAvatarController(tableView: UITableView, cell: UITableViewCell) -> Void {
        let changeAvatarAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        changeAvatarAlertController.addAction(UIAlertAction.init(title: AMLocalizedString("cancel", ""), style: .cancel, handler: nil))
        
        let fromPhotosAlertAction = UIAlertAction.init(title: AMLocalizedString("choosePhotoVideo", "Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA"), style: .default) { (UIAlertAction) in
            DevicePermissionsHelper.photosPermission(completionHandler: { (granted) in
                if granted {
                    self.showImagePicker(sourceType: .photoLibrary)
                } else {
                    DevicePermissionsHelper.alertPhotosPermission()
                }
            })
        }
        changeAvatarAlertController.addAction(fromPhotosAlertAction)
        
        let captureAlertAction = UIAlertAction.init(title: AMLocalizedString("capturePhotoVideo", "Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA."), style: .default) { (UIAlertAction) in
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
        
        changeAvatarAlertController.modalPresentationStyle = .popover;
        changeAvatarAlertController.popoverPresentationController?.sourceRect = cell.frame;
        changeAvatarAlertController.popoverPresentationController?.sourceView = tableView;
        
        let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: MEGASdkManager.sharedMEGASdk().myUser?.handle ?? ~0) ?? "")
        
        if FileManager.default.fileExists(atPath: avatarFilePath) {
            let removeAvatarAlertAction = UIAlertAction.init(title: AMLocalizedString("Remove Photo", "Button to remove some photo, e.g. avatar photo. Try to keep the text short (as in English)"), style: .default) { (UIAlertAction) in
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
        let isBusiness = MEGASdkManager.sharedMEGASdk().isBusinessAccount
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
        if MEGASdkManager.sharedMEGASdk().isBusinessAccount {
            return [.upgrade, .role]
        } else {
            return [.upgrade]
        }
    }
    
    func rowsForSessionSection() -> [SessionSectionRow] {
        return [.logout]
    }
    
    func presentChangeViewController(changeType: ChangeType) -> Void {
        let changePasswordViewController = UIStoryboard.init(name: "ChangeCredentials", bundle: nil).instantiateViewController(withIdentifier: "ChangePasswordViewControllerID") as! ChangePasswordViewController
        changePasswordViewController.changeType = changeType
        if changeType == .email {
            switch twoFactorAuthStatus {
            case .unknown:
                 guard let myEmail = MEGASdkManager.sharedMEGASdk().myEmail else {
                    return
                 }
                 MEGASdkManager.sharedMEGASdk().multiFactorAuthCheck(withEmail: myEmail, delegate: MEGAGenericRequestDelegate(completion: { (request, error) in
                    self.twoFactorAuthStatus = request.flag ? .enabled : .disabled
                    self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                    if self.navigationController?.children.count != 2 {
                        return
                    }
                    changePasswordViewController.isTwoFactorAuthenticationEnabled = request.flag
                    let navigationController = MEGANavigationController.init(rootViewController: changePasswordViewController)
                    navigationController.addLeftDismissButton(withText: AMLocalizedString("cancel", "Button title to cancel something"))
                    
                    self.present(navigationController, animated: true, completion: nil)
                 }))
                 twoFactorAuthStatus = .querying
                 tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
            case .querying:
                return
            case .disabled, .enabled:
                    changePasswordViewController.isTwoFactorAuthenticationEnabled = self.twoFactorAuthStatus == .enabled
                    let navigationController = MEGANavigationController.init(rootViewController: changePasswordViewController)
                    navigationController.addLeftDismissButton(withText: AMLocalizedString("cancel", "Button title to cancel something"))
                    
                    present(navigationController, animated: true, completion: nil)
            }
        } else {
            let navigationController = MEGANavigationController.init(rootViewController: changePasswordViewController)
            navigationController.addLeftDismissButton(withText: AMLocalizedString("cancel", "Button title to cancel something"))
            
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func showAddPhoneNumber() {
        let addPhoneNumberController = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "AddPhoneNumberViewControllerID")
        addPhoneNumberController.modalPresentationStyle = .fullScreen
        present(addPhoneNumberController, animated: true, completion: nil)
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
            return AMLocalizedString("masterKey", "Title for the MEGA Recovery Key")
        case .plan:
            return AMLocalizedString("Plan", "Title of the section about the plan in the storage tab in My Account Section")
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch tableViewSections()[section] {
        case .security:
            return AMLocalizedString("If you lose this Recovery key and forget your password, [B]all your files, folders and messages will be inaccessible, even by MEGA[/B].", "").replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "")
        case .plan:
            guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
                return nil
            }
            var planFooterString = ""

            if accountDetails.type != .free {
                if accountDetails.subscriptionRenewTime > 0 {
                    let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.subscriptionRenewTime))
                    planFooterString = AMLocalizedString("Renews on", "Label for the ‘Renews on’ text into the my account page, indicating the renewal date of a subscription - (String as short as possible).") + " " + expiryDateFormatterOfProfessionalAccountExpiryDate(renewDate).localisedString(from: renewDate)
                } else if accountDetails.proExpiration > 0 && accountDetails.type != .business {
                    let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.proExpiration))
                    planFooterString = String(format: AMLocalizedString("expiresOn", "Text that shows the expiry date of the account PRO level"), expiryDateFormatterOfProfessionalAccountExpiryDate(renewDate).localisedString(from: renewDate))
                }
            }
            return planFooterString
        case .session:
            if FileManager.default.mnz_existsOfflineFiles() && MEGASdkManager.sharedMEGASdk().transfers.size != 0 {
                return AMLocalizedString("When you logout, files from your Offline section will be deleted from your device and ongoing transfers will be cancelled.", "Warning message to alert user about logout in My Account section if has offline files and transfers in progress.")
            } else if FileManager.default.mnz_existsOfflineFiles() {
                return AMLocalizedString("When you logout, files from your Offline section will be deleted from your device.", "Warning message to alert user about logout in My Account section if has offline files.")
            } else if MEGASdkManager.sharedMEGASdk().transfers.size != 0 {
                return AMLocalizedString("When you logout, ongoing transfers will be cancelled.", "Warning message to alert user about logout in My Account section if has transfers in progress.")
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
                cell.nameLabel.text = AMLocalizedString("changeName", "Button title that allows the user change his name")
            case .changePhoto:
                let hasPhotoAvatar = FileManager.default.fileExists(atPath:Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: MEGASdkManager.sharedMEGASdk().myUser?.handle ?? ~0) ?? ""))
                cell.nameLabel.text = hasPhotoAvatar ? AMLocalizedString("Change Photo", "Button that allows the user the change a photo, e.g. his avatar photo ") : AMLocalizedString("Add Photo", "Button that allows the user the add a photo, e.g avatar photo")
            case .changeEmail:
                switch twoFactorAuthStatus {
                case .unknown, .disabled, .enabled:
                    cell.nameLabel?.isEnabled = true
                    cell.accessoryView = nil
                case .querying:
                    cell.nameLabel?.isEnabled = false
                    let activityIndicator = UIActivityIndicatorView(style: .gray)
                    activityIndicator.startAnimating()
                    cell.accessoryView = activityIndicator
                }
                cell.nameLabel.text = AMLocalizedString("Change Email", "The title of the alert dialog to change the email associated to an account.")
            case .phoneNumber:
                if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() == nil {
                    cell.nameLabel.text = AMLocalizedString("Add Phone Number", "Add Phone Number title")
                } else {
                    cell.nameLabel.text = AMLocalizedString("Phone Number", "Text related to verified phone number. Used as title or cell description.")
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
                cell.nameLabel.text = AMLocalizedString("changePasswordLabel", "Section title where you can change your MEGA's password")
            }
            return cell
        case .security:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecoveryKeyID", for: indexPath) as! RecoveryKeyTableViewCell
            cell.recoveryKeyContainerView.backgroundColor = UIColor.mnz_tertiaryBackgroundGrouped(traitCollection)
            cell.recoveryKeyLabel.text = AMLocalizedString("masterKey", "Title for the MEGA Recovery Key")+".txt"
            cell.backupRecoveryKeyLabel.text = AMLocalizedString("backupRecoveryKey", "Label for recovery key button")
            cell.backupRecoveryKeyLabel.textColor = UIColor.mnz_turquoise(for: traitCollection)
            return cell
        case .plan:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.nameLabel.text = AMLocalizedString("upgradeAccount", "Button title which triggers the action to upgrade your MEGA account level")
            guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
                return cell
            }
            let accountType = accountDetails.type
            
            switch rowsForPlanSection()[indexPath.row] {
            case .upgrade:
                switch accountType {
                case .free:
                    cell.detailLabel.text = AMLocalizedString("Free", "Text relative to the MEGA account level. UPPER CASE")
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
                    cell.detailLabel.text = "Lite"
                    cell.detailLabel.textColor = UIColor.systemOrange
                case .business:
                    if MEGASdkManager.sharedMEGASdk().businessStatus == .active {
                        cell.detailLabel.text = AMLocalizedString("Active", "")
                    } else {
                        cell.detailLabel.text = AMLocalizedString("Payment overdue", "Business expired account Overdue payment page header.")
                    }
                    cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
                    cell.nameLabel.text = AMLocalizedString("Business", "")
                    cell.accessoryType = .none
                default:
                    cell.detailLabel.text = "..."
                }
            case .role:
                if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                    cell.detailLabel.text = AMLocalizedString("Administrator", "")
                } else {
                    cell.detailLabel.text = AMLocalizedString("User", "Business user role")
                }
                cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
                cell.nameLabel.text = AMLocalizedString("Role:", "title of a field to show the role or position (you can use whichever is best for translation) of the user in business accounts").replacingOccurrences(of: ":", with: "")
                cell.accessoryType = .none
            }
            return cell
        case .session:
            switch rowsForSessionSection()[indexPath.row] {
            case .logout:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutID", for: indexPath) as! LogoutTableViewCell
                cell.logoutLabel.text = AMLocalizedString("logoutLabel", "Title of the button which logs out from your account.")
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
                let changeNameNavigationController = UIStoryboard.init(name: "MyAccount", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameNavigationControllerID")
                navigationController?.present(changeNameNavigationController, animated: true)
            case .changePhoto:
                guard let cell = tableView.cellForRow(at: indexPath) else {
                    return
                }
                presentChangeAvatarController(tableView:tableView, cell: cell)
            case .changeEmail:
                presentChangeViewController(changeType: .email)
            case .phoneNumber:
                if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() == nil {
                    showAddPhoneNumber()
                } else {
                    showPhoneNumberView()
                }
            case .changePassword:
                presentChangeViewController(changeType: .password)
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
                if !MEGASdkManager.sharedMEGASdk().isBusinessAccount {
                    if ((MEGASdkManager.sharedMEGASdk().mnz_accountDetails) != nil) {
                        let upgradeViewController = UIStoryboard.init(name: "UpgradeAccount", bundle: nil).instantiateViewController(withIdentifier: "UpgradeTableViewControllerID")
                        navigationController?.pushViewController(upgradeViewController, animated: true)
                    } else {
                        MEGAReachabilityManager.isReachableHUDIfNot()
                    }
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
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: - MEGARequestDelegate

extension ProfileViewController: MEGARequestDelegate {
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard let myUser = api.myUser else {
            if request.type == .MEGARequestTypeLogout {
                api.remove(self)
            }
            return;
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
                    SVProgressHUD.showError(withStatus: request.requestString + " " + AMLocalizedString(error.name, nil))
                    return
                }
            }
            
            let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: myUser.handle) ?? "")
            if request.file == nil {
                FileManager.default.mnz_removeItem(atPath: avatarFilePath)
            }
            avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
        case .MEGARequestTypeAccountDetails:
            tableView.reloadData()
            nameLabel.text = myUser.mnz_fullName
            emailLabel.text = api.myEmail
            avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            configureGestures()
            
        case .MEGARequestTypeGetUserEmail:
            emailLabel.text = request.email
            
        case .MEGARequestTypeCheckSMSVerificationCode, .MEGARequestTypeResetSmsVerifiedNumber:
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
        default:
            break;
        }
    }
}
