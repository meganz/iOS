import MEGADomain
import UIKit

protocol DocScannerFileInfoTableCellDelegate: AnyObject {
    func filenameChanged(_ newFilename: String)
    func containsCharactersNotAllowed()
}

class DocScannerFileNameTableCell: UITableViewCell {
    @IBOutlet weak var fileImageView: UIImageView!
    @IBOutlet weak var filenameTextField: UITextField!
    
    weak var delegate: (any DocScannerFileInfoTableCellDelegate)?
    
    var originalFilename: String? {
        didSet {
            filenameTextField?.placeholder = originalFilename
        }
    }
    var currentFilename: String? {
        didSet {
            filenameTextField?.text = currentFilename
        }
    }
    
    func configure(filename: String, fileType: String?) {
        backgroundColor = .mnz_backgroundElevated()
        
        self.originalFilename = filename
        self.currentFilename = filename
        fileImageView.image = NodeAssetsManager.shared.image(for: fileType ?? "")
    }
}

extension DocScannerFileNameTableCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField.text?.isEmpty == true {
            guard let originalFileName = originalFilename else {
                return true
            }
            textField.text = originalFileName
            textField.textColor = UIColor.label
        }
        
        return true
    }
    
    @IBAction func textFiledEditingChanged(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        
        if textField.text?.isEmpty == true {
            guard let originalFileName = originalFilename else {
                return
            }
            delegate?.filenameChanged(originalFileName)
        } else {
            let containsInvalidChars = textField.text?.mnz_containsInvalidChars() ?? false
            textField.textColor = containsInvalidChars ? UIColor.systemRed : UIColor.label
            currentFilename = text
            delegate?.filenameChanged(text)
            if containsInvalidChars {
                delegate?.containsCharactersNotAllowed()
            }
        }
    }
}
