
import UIKit

class AddNickNameViewController: UIViewController {

    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    
    @objc var user: MEGAUser?
    @objc var nicknameChangedHandler: ((String?) -> Void)?
    @objc var nickname: String? {
        didSet {
            guard let nickname = nickname,
                let nicknameTextField = nicknameTextField else {
                return
            }
            
            nicknameTextField.text = nickname
        }
    }
    
    // MARK:- Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = AMLocalizedString("Set Nickname", "Contact details screen: Set the alias(nickname) for a user")
        cancelBarButtonItem.title = AMLocalizedString("cancel", "Cancels the add nickname screen")
        saveBarButtonItem.title = AMLocalizedString("save", "Saves the new nickname")
        nicknameLabel.text = AMLocalizedString("Alias/ Nickname", "Add nickname screen: This text appears above the alias(nickname) entry")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nickname = nickname {
            nicknameTextField.text = nickname
        }
        
        nicknameTextField.becomeFirstResponder()
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
    
    // MARK:- Private methods.
    
    private func saveNickname() {
        guard let nicknameTextFieldText = nicknameTextField.text,
            let user = user else {
            return
        }
        
        guard nickname != nicknameTextFieldText else {
            dismissViewController()
            return
        }
        
        let newNickname = nicknameTextFieldText.trim
        
        let genericRequestDelegate = MEGAGenericRequestDelegate { request, error in
            SVProgressHUD.dismiss()
            
            if error.type == .apiOk {
                self.user?.mnz_nickname = newNickname
                self.updateHandler(withNickname: newNickname)
            } else {
                SVProgressHUD.showError(withStatus: request.requestString + " " + error.name)
            }
            
            self.dismissViewController()
        }
        
        SVProgressHUD.show()
        MEGASdkManager.sharedMEGASdk().setUserAlias(newNickname, forHandle: user.handle, delegate: genericRequestDelegate)
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
}

extension AddNickNameViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveNickname()
        return true
    }
}
