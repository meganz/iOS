
import UIKit

class ContactsHeaderFooterView: UITableViewHeaderFooterView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var backgroundColorView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        setup()
    }
    
    //MARK: - Private
    
    private func setup() {
        self.contentView.backgroundColor = UIColor.mnz_tertiaryBackground(self.traitCollection)
        
        self.topSeparatorView.backgroundColor = UIColor.mnz_separatorColor(for: self.traitCollection)
        self.bottomSeparatorView.backgroundColor = UIColor .mnz_separatorColor(for: self.traitCollection)
    }
}
