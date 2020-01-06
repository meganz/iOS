
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
    
    private var genericRequestDelegate: MEGAGenericRequestDelegate {
        let genericRequestDelegate = MEGAGenericRequestDelegate {
            _, error in
            guard let error = error else {
                return
            }
            
            if error.type != .apiOk {
                self.user?.mnz_nickname = self.nickname
                self.updateHandler(withNickname: self.nickname)
            }
        }!
        return genericRequestDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Set Nickname".localized()
        cancelBarButtonItem.title = "Cancel".localized()
        saveBarButtonItem.title = "save".localized()
        nicknameLabel.text = "Alias/ Nickname".localized()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nickname = nickname {
            nicknameTextField.text = nickname
            saveBarButtonItem.isEnabled = shouldAllowToSave(newNickname: nickname)
        }
        
        nicknameTextField.becomeFirstResponder()
    }
    
    // MARK:- IBActions
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        nicknameTextField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        saveNickname()
    }
    
    @IBAction func nicknameEdited(_ sender: UITextField) {
        guard let newNickname = sender.text else {
            return
        }
        
        saveBarButtonItem.isEnabled = shouldAllowToSave(newNickname: newNickname)
    }
    
    // MARK:- Private methods.
    private func shouldAllowToSave(newNickname: String) -> Bool {
        return !newNickname.isEmpty && newNickname != nickname
    }
    
    private func saveNickname() {
        guard let newNickname = nicknameTextField.text,
            let user = user else {
            return
        }
        
        guard nickname != newNickname else {
            dismissViewController()
            return
        }
        
        MEGASdkManager.sharedMEGASdk()?.setUserAlias(newNickname,
                                                     forHandle: user.handle,
                                                     delegate: genericRequestDelegate)
        user.mnz_nickname = newNickname
        updateHandler(withNickname: newNickname)
        dismissViewController()
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
