import MEGADesignToken
import UIKit

final class SearchHintTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIColor.isDesignTokenEnabled() {
            titleLabel.textColor = TokenColors.Text.primary
            contentView.backgroundColor = TokenColors.Background.page
        }
    }

    func configure(with hintModel: HomeSearchHintViewModel) {
        titleLabel.text = hintModel.text
    }
}
