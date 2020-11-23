import UIKit

final class SearchHintTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with hintModel: HomeSearchHintViewModel) {
        titleLabel.text = hintModel.text
    }
}
