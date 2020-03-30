
import UIKit

class NicknameViewController: UIViewController {

    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var removeNicknameButtonView: UIView!
    @IBOutlet weak var removeNicknameButton: UIButton!

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
    
    // MARK:- Lifecycle
    
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
        
        updateAppearance()
    }
    
    // MARK:- IBActions
    
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
    
    // MARK:- Orientation method.

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.iPhone4X || UIDevice.current.iPhone5X {
            return [.portrait, .portraitUpsideDown]
        }
        
        return .all
    }
    
    // MARK:- Private methods.
    
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
        
        let genericRequestDelegate = MEGAGenericRequestDelegate { request, error in
            SVProgressHUD.dismiss()
            
            if error.type == .apiOk {
                if let user = self.user {
                    NotificationCenter.default.post(name: NSNotification.Name.MEGContactNicknameChange,
                                                    object: nil,
                                                    userInfo: ["user" : user])
                    
                    user.mnz_nickname = nickname
                }
                
                self.updateHandler(withNickname: nickname)
            } else {
                SVProgressHUD.showError(withStatus: request.requestString + " " + error.name)
            }
            
            self.dismissViewController()
        }
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        MEGASdkManager.sharedMEGASdk().setUserAlias(nickname, forHandle: user.handle, delegate: genericRequestDelegate)
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
        
        title = (nickname != nil) ?
            AMLocalizedString("Edit Nickname", "Contact details screen: Set the alias(nickname) for a user") :
            AMLocalizedString("Set Nickname", "Contact details screen: Set the alias(nickname) for a user")
        removeNicknameButtonView.isHidden = (nickname == nil)
        removeNicknameButton.setTitle(AMLocalizedString("Remove Nickname", "Edit nickname screen: Remove nickname button title"),
                                      for: .normal)
        cancelBarButtonItem.title = AMLocalizedString("cancel", "Cancels the add nickname screen")
        saveBarButtonItem.title = AMLocalizedString("save", "Saves the new nickname")
        nicknameLabel.text = AMLocalizedString("Alias/ Nickname", "Add nickname screen: This text appears above the alias(nickname) entry")
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        removeNicknameButton.setTitleColor(UIColor.mnz_redMain(), for: .normal)
    }
}

extension NicknameViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveNickname()
        return true
    }
}
