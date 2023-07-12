import UIKit

@objc protocol SingleCodeTextFieldDelegate: AnyObject {
    func didDeleteBackwardInTextField(_ textField: SingleCodeTextField)
}

class SingleCodeTextField: UITextField {

    @IBOutlet weak var singleCodeDelegate: (any SingleCodeTextFieldDelegate)?

    override func deleteBackward() {
        super.deleteBackward()

        singleCodeDelegate?.didDeleteBackwardInTextField(self)
    }
}
