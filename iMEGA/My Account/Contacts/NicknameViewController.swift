import MEGADesignToken
import MEGAL10n
import MEGASDKRepo
import UIKit

class NicknameViewController: UIViewController {

    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var nicknameView: UIView!
    @IBOutlet weak var nicknameTopSeparatorView: UIView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var nicknameBottomSeparatorView: UIView!
    
    @IBOutlet weak var removeNicknameButtonTopSeparatorView: UIView!
    @IBOutlet weak var removeNicknameButtonView: UIView!
    @IBOutlet weak var removeNicknameButton: UIButton!
    @IBOutlet weak var removeNicknameButtonBottomSeparatorView: UIView!

    @objc var user: MEGAUser?
    @objc var nicknameChangedHandler: ((String?) -> Void)?
    @objc var nickname: String? {
        didSet {
            guard isViewLoaded else {
                return
            }

            nicknameTextField.text = nickname
            removeNicknameButtonView.isHidden = (nickname == nil)
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nicknameTextField.becomeFirstResponder()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - IBActions

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        nicknameTextField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            saveNickname()
        }
    }

    @IBAction func removeNicknameTapped(_ sender: UIButton) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            nicknameTextField.text = nil
            save(nickname: nil)
        }
    }

    // MARK: - Private methods.

    private func saveNickname() {
        guard let nicknameTextFieldText = nicknameTextField.text,
            nickname != nicknameTextFieldText else {
            dismissViewController()
            return
        }

        let newNickname = nicknameTextFieldText.trim
        save(nickname: newNickname)
    }

    private func save(nickname: String?) {
        guard let user = user else {
            return
        }
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        MEGASdk.shared.setUserAlias(nickname, forHandle: user.handle, delegate: RequestDelegate { [weak self] (result) in
            SVProgressHUD.dismiss()
            guard let self else { return }
            switch result {
            case .success:
                if let user = self.user {
                    NotificationCenter.default.post(name: NSNotification.Name.MEGContactNicknameChange,
                                                    object: nil,
                                                    userInfo: ["user": user])

                    user.mnz_nickname = nickname
                }

                updateHandler(withNickname: nickname)
            case .failure(let error):
                SVProgressHUD.showError(withStatus: Strings.localized(error.name, comment: ""))
            }
            
            dismissViewController()
        })
    }

    private func dismissViewController() {
        nicknameTextField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }

    private func updateHandler(withNickname nickname: String?) {
        if let nicknameChangedHandler = self.nicknameChangedHandler {
            nicknameChangedHandler(nickname)
        }
    }

    private func configureUI() {
        if let nickname = nickname {
            nicknameTextField.text = nickname
        }

        title = (nickname != nil) ? Strings.Localizable.editNickname : Strings.Localizable.setNickname
        removeNicknameButtonView.isHidden = (nickname == nil)
        removeNicknameButton.setTitle(Strings.Localizable.removeNickname, for: .normal)
        cancelBarButtonItem.title = Strings.Localizable.cancel
        saveBarButtonItem.title = Strings.Localizable.save
        nicknameLabel.text = Strings.Localizable.aliasNickname
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        
        nicknameView.backgroundColor = TokenColors.Background.page
        nicknameLabel.textColor = TokenColors.Text.secondary
        nicknameTopSeparatorView.backgroundColor = TokenColors.Border.strong
        nicknameBottomSeparatorView.backgroundColor = TokenColors.Border.strong
        
        removeNicknameButton.backgroundColor = TokenColors.Background.page
        removeNicknameButton.setTitleColor(TokenColors.Text.error, for: .normal)
        removeNicknameButtonTopSeparatorView.backgroundColor = TokenColors.Border.strong
        removeNicknameButtonBottomSeparatorView.backgroundColor = TokenColors.Border.strong
    }
}

extension NicknameViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveNickname()
        return true
    }
}
