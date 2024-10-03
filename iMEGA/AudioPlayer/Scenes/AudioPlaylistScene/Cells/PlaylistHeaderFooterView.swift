import MEGADesignToken
import UIKit

final class PlaylistHeaderFooterView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        updateAppearance()
    }
    
    func configure(title: String) {
        typeLabel.text = title
    }
    
    // MARK: - Private functions
    private func updateAppearance() {
        typeLabel.textColor = TokenColors.Text.primary
        contentView.backgroundColor = TokenColors.Background.page
        separatorView.backgroundColor = TokenColors.Border.strong
    }
}
