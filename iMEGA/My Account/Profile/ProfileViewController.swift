
import UIKit

enum TwoFactorAuthStatus {
    case Unknown
    case Querying
    case Disabled
    case Enabled
}

@objc class ProfileViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var avatarViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    private var avatarExpandedPosition: CGFloat = 0.0
    private var avatarCollapsedPosition: CGFloat = 0.0
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.locale = NSLocale.autoupdatingCurrent
        return dateFormatter
    }()
    
    private var twoFactorAuthStatus:TwoFactorAuthStatus = .Unknown
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    // MARK: - Private
    
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
        changeAvatarAlertController.addAction(UIAlertAction.init(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        
        let fromPhotosAlertAction = UIAlertAction.init(title: NSLocalizedString("choosePhotoVideo", comment: "Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA"), style: .default) { (UIAlertAction) in
            DevicePermissionsHelper.photosPermission(completionHandler: { (granted) in
                if granted {
                    self.showImagePicker(sourceType: .photoLibrary)
                } else {
                    DevicePermissionsHelper.alertPhotosPermission()
                }
            })
        }
        fromPhotosAlertAction.mnz_setTitleTextColor(UIColor.mnz_black333333())
        changeAvatarAlertController.addAction(fromPhotosAlertAction)
        
        let captureAlertAction = UIAlertAction.init(title: NSLocalizedString("capturePhotoVideo", comment: "Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA."), style: .default) { (UIAlertAction) in
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
        captureAlertAction.mnz_setTitleTextColor(UIColor.mnz_black333333())
        changeAvatarAlertController.addAction(captureAlertAction)
        
        changeAvatarAlertController.modalPresentationStyle = .popover;
        changeAvatarAlertController.popoverPresentationController?.sourceRect = cell.frame;
        changeAvatarAlertController.popoverPresentationController?.sourceView = tableView;
        
        let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: MEGASdkManager.sharedMEGASdk().myUser?.handle ?? ~0) ?? "")
        
        if FileManager.default.fileExists(atPath: avatarFilePath) {
            let removeAvatarAlertAction = UIAlertAction.init(title: NSLocalizedString("removeAvatar", comment: "Button to remove avatar. Try to keep the text short (as in English)"), style: .default) { (UIAlertAction) in
                MEGASdkManager.sharedMEGASdk().setAvatarUserWithSourceFilePath(nil)
            }
            removeAvatarAlertAction.mnz_setTitleTextColor(UIColor.mnz_black333333())
            changeAvatarAlertController.addAction(removeAvatarAlertAction)
        }
        
        self.present(changeAvatarAlertController, animated: true, completion: nil)
    }
    
    // MARK: - IBActions
    
    @IBAction func backTouchUpInside(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - UITableViewDataSource

extension ProfileViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if MEGASdkManager.sharedMEGASdk().isBusinessAccount && !MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                return 2
            } else {
                return 4
            }
        } else if section == 2 {
            if MEGASdkManager.sharedMEGASdk().isBusinessAccount {
                return 2
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("masterKey", comment: "Title for the MEGA Recovery Key")
        } else if section == 2 {
            return NSLocalizedString("Subscription plan", comment: "Subscription plan")
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("If you lose this Recovery key and forget your password, [B]all your files, folders and messages will be inaccessible, even by MEGA[/B].", comment: "").replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "")
        } else if section == 2 {
            guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
                return nil
            }
            if accountDetails.type != .free {
                if accountDetails.subscriptionRenewTime > 0 {
                    let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.subscriptionRenewTime))
                    let renewsExpiresString = NSLocalizedString("Renews on", comment: "Label for the ‘Renews on’ text into the my account page, indicating the renewal date of a subscription - (String as short as possible).") + " " + dateFormatter.string(from: renewDate)
                    return renewsExpiresString
                } else if accountDetails.proExpiration > 0 && accountDetails.type != .business {
                    let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.proExpiration))
                    let renewsExpiresString = String(format: NSLocalizedString("expiresOn", comment: "Text that shows the expiry date of the account PRO level"), dateFormatter.string(from: renewDate))
                    return renewsExpiresString
                }
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "cellID")
            switch indexPath.row {
            case 0:
                if MEGASdkManager.sharedMEGASdk().isBusinessAccount && !MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                    cell.textLabel?.text = NSLocalizedString("changeAvatar", comment: "button that allows the user the change his avatar")
                } else {
                    cell.textLabel?.text = NSLocalizedString("changeName", comment: "Button title that allows the user change his name")
                }
            case 1:
                if MEGASdkManager.sharedMEGASdk().isBusinessAccount && !MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                    cell.textLabel?.text = NSLocalizedString("changePasswordLabel", comment: "Section title where you can change your MEGA's password").capitalized
                } else {
                    cell.textLabel?.text = NSLocalizedString("changeAvatar", comment: "button that allows the user the change his avatar")
                }
            case 2:
                switch twoFactorAuthStatus {
                case .Unknown, .Disabled, .Enabled:
                    cell.textLabel?.isEnabled = true
                    cell.accessoryView = nil
                case .Querying:
                    cell.textLabel?.isEnabled = false
                    let activityIndicator = UIActivityIndicatorView(style: .gray)
                    activityIndicator.startAnimating()
                    cell.accessoryView = activityIndicator
                }
                cell.textLabel?.text = NSLocalizedString("Change Email", comment: "The title of the alert dialog to change the email associated to an account.")
            case 3:
                cell.textLabel?.text = NSLocalizedString("changePasswordLabel", comment: "Section title where you can change your MEGA's password").capitalized
            default:
                cell.textLabel?.text = "default"
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecoveryKeyID", for: indexPath) as! RecoveryKeyTableViewCell
            cell.recoveryKeyLabel.text = NSLocalizedString("masterKey", comment: "Title for the MEGA Recovery Key")+".txt"
            cell.backupRecoveryKeyLabel.text = NSLocalizedString("backupRecoveryKey", comment: "Label for recovery key button")
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpgradePlanID", for: indexPath) as! UpgradePlanTableViewCell
            cell.upgradePlanLabel?.text = NSLocalizedString("upgradeAccount", comment: "Button title which triggers the action to upgrade your MEGA account level")
            guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
                return cell
            }
            let accountType = accountDetails.type
            if indexPath.row == 0 {
                switch accountType {
                case .free:
                    cell.accountTypeLabel.text = NSLocalizedString("free", comment: "Text relative to the MEGA account level. UPPER CASE")
                case .proI:
                    cell.accountTypeLabel.text = "Pro I"
                    cell.accountTypeLabel.textColor = UIColor.mnz_redProI()
                case .proII:
                    cell.accountTypeLabel.text = "Pro II"
                    cell.accountTypeLabel.textColor = UIColor.mnz_redProII()
                case .proIII:
                    cell.accountTypeLabel.text = "Pro III"
                    cell.accountTypeLabel.textColor = UIColor.mnz_redProIII()
                case .lite:
                    cell.accountTypeLabel.text = "Lite"
                    cell.accountTypeLabel.textColor = UIColor.mnz_orangeFFA500()
                case .business:
                    if MEGASdkManager.sharedMEGASdk().businessStatus == .active {
                        cell.accountTypeLabel.text = NSLocalizedString("Active", comment: "")
                    } else {
                        cell.accountTypeLabel.text = NSLocalizedString("Payment Overdue", comment: "Business expired account Overdue payment page header.")
                    }
                    cell.upgradePlanLabel.text = NSLocalizedString("Business", comment: "")
                    cell.accessoryType = .none
                default:
                    cell.accountTypeLabel.text = "..."
                }
            } else {
                if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                    cell.accountTypeLabel.text = NSLocalizedString("Administrator", comment: "")
                } else {
                    cell.accountTypeLabel.text = NSLocalizedString("user", comment: "user (singular) label indicating is receiving some info, for example shared folders").capitalized
                }
                cell.upgradePlanLabel.text = NSLocalizedString("Role", comment: "title of a field to show the role or position (you can use whichever is best for translation) of the user in business accounts")
                cell.accessoryType = .none
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutID", for: indexPath) as! LogoutTableViewCell
            cell.logoutLabel.text = NSLocalizedString("logoutLabel", comment: "Title of the button which logs out from your account.")
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if MEGASdkManager.sharedMEGASdk().isBusinessAccount && !MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                    guard let cell = tableView.cellForRow(at: indexPath) else {
                        return
                    }
                    presentChangeAvatarController(tableView:tableView, cell: cell)
                } else {
                    let changeNameNavigationController = UIStoryboard.init(name: "MyAccount", bundle: nil).instantiateViewController(withIdentifier: "ChangeNameViewControllerID")
                    navigationController?.pushViewController(changeNameNavigationController, animated: true)
                }
            } else if indexPath.row == 1 {
                if MEGASdkManager.sharedMEGASdk().isBusinessAccount && !MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                    pushChangeViewController(changeType: .password)
                } else {
                    guard let cell = tableView.cellForRow(at: indexPath) else {
                        return
                    }
                    presentChangeAvatarController(tableView:tableView, cell: cell)
                }
            } else if indexPath.row == 2 {
                pushChangeViewController(changeType: .email)
            } else {
                pushChangeViewController(changeType: .password)
            }
        } else if indexPath.section == 1 {
            let recoveryKeyViewController = UIStoryboard.init(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "MasterKeyViewControllerID")
            navigationController?.pushViewController(recoveryKeyViewController, animated: true)
        } else if indexPath.section == 2 {
            if !MEGASdkManager.sharedMEGASdk().isBusinessAccount {
                if ((MEGASdkManager.sharedMEGASdk().mnz_accountDetails) != nil) {
                    let upgradeViewController = UIStoryboard.init(name: "MyAccount", bundle: nil).instantiateViewController(withIdentifier: "UpgradeID")
                    navigationController?.pushViewController(upgradeViewController, animated: true)
                } else {
                    MEGAReachabilityManager.isReachableHUDIfNot()
                }
            }
        } else {
            if MEGAReachabilityManager.isReachableHUDIfNot() {
                guard let showPasswordReminderDelegate = MEGAShowPasswordReminderRequestDelegate(toLogout: true) else {
                    return
                }
                MEGASdkManager.sharedMEGASdk().shouldShowPasswordReminderDialog(atLogout: true, delegate: showPasswordReminderDelegate)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func pushChangeViewController(changeType: ChangeType) -> Void {
        let changePasswordViewController = UIStoryboard.init(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "ChangePasswordViewControllerID") as! ChangePasswordViewController
        changePasswordViewController.changeType = changeType
        if changeType == .email {
            switch twoFactorAuthStatus {
            case .Unknown:
                 guard let myEmail = MEGASdkManager.sharedMEGASdk().myEmail else {
                    return
                 }
                 MEGASdkManager.sharedMEGASdk().multiFactorAuthCheck(withEmail: myEmail, delegate: MEGAGenericRequestDelegate(completion: { (request, error) in
                    self.twoFactorAuthStatus = request.flag ? .Enabled : .Disabled
                    self.tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
                    if self.navigationController?.children.count != 2 {
                        return
                    }
                    changePasswordViewController.isTwoFactorAuthenticationEnabled = request.flag
                    self.navigationController?.pushViewController(changePasswordViewController, animated: true)
                 }))
                 twoFactorAuthStatus = .Querying
                 tableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
            case .Querying:
                return
            case .Disabled, .Enabled:
                    changePasswordViewController.isTwoFactorAuthenticationEnabled = self.twoFactorAuthStatus == .Enabled
                    self.navigationController?.pushViewController(changePasswordViewController, animated: true)
            }
        } else {
            navigationController?.pushViewController(changePasswordViewController, animated: true)
        }
    }
}

//MARK: - MEGARequestDelegate

extension ProfileViewController: MEGARequestDelegate {
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard let myUser = api.myUser else {
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
                    SVProgressHUD.showError(withStatus: request.requestString+" "+error.name)
                    return
                }
            }
            
            let avatarFilePath: String = Helper.path(forSharedSandboxCacheDirectory: "thumbnailsV3") + "/" + (MEGASdk.base64Handle(forUserHandle: myUser.handle) ?? "")
            if request.file == nil {
                FileManager.default.mnz_removeItem(atPath: avatarFilePath)
            }
            avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            
        case .MEGARequestTypeAccountDetails:
            tableView.reloadData()
            nameLabel.text = myUser.mnz_fullName
            emailLabel.text = api.myEmail
            avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: myUser.handle)
            configureGestures()
            
        default:
            break;
        }
    }
}
