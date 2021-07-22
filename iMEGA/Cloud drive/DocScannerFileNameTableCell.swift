
import UIKit

protocol DocScannerFileInfoTableCellDelegate: AnyObject {
    func filenameChanged(_ newFilename: String)
}

class DocScannerFileNameTableCell: UITableViewCell {
    @IBOutlet weak var fileImageView: UIImageView!
    @IBOutlet weak var filenameTextField: UITextField!
    
    weak var delegate: DocScannerFileInfoTableCellDelegate?
    
    var filename: String? {
        didSet {
            filenameTextField?.text = filename
        }
    }
    
    func configure(filename: String, fileType: String?) {
        backgroundColor = .mnz_secondaryBackgroundGrouped(traitCollection)
        
        self.filename = filename
        fileImageView.mnz_setImage(forExtension: fileType)
    }
}

extension DocScannerFileNameTableCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func textFiledEditingChanged(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        let containsInvalidChars = textField.text?.mnz_containsInvalidChars() ?? false
        textField.textColor = containsInvalidChars ? UIColor.mnz_redError() : UIColor.mnz_label()
        filename = text
        delegate?.filenameChanged(text)
    }
}
