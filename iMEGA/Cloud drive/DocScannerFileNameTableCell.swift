
import UIKit

protocol DocScannerFileInfoTableCellDelegate: class {
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
        self.filename = filename
        fileImageView.mnz_setImage(forExtension: fileType)
    }
}

extension DocScannerFileNameTableCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text,
            !text.isEmpty else {
                filenameTextField?.text = filename
                return true
        }
        
        filename = text
        delegate?.filenameChanged(text)
        textField.resignFirstResponder()
        return true
    }
}
