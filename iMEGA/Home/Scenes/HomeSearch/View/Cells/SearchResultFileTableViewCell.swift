import UIKit

class SearchResultFileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var folderLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var moreActionButton: UIButton! {
        didSet {
            moreActionButton.addTarget(self, action: #selector(didTapMoreActionButton(button:)), for: .touchUpInside)
        }
    }
    
    private var uuid: UUID = UUID()
    private var handle: HandleEntity?
    private var moreAction: ((HandleEntity, UIButton) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        uuid = UUID()
        handle = nil
        moreAction = nil
    }
    
    func configure(with fileModel: HomeSearchResultFileViewModel) {
        fileNameLabel.text = fileModel.name
        folderLabel.text = fileModel.folder
        let currentUUID = uuid
        fileModel.thumbnail? { [weak self] image in
            asyncOnMain {
                guard currentUUID == self?.uuid else { return }
                self?.thumbnailImageView.image = image
            }
        }
        handle = fileModel.handle
        moreAction = fileModel.moreAction
    }

    @objc private func didTapMoreActionButton(button: UIButton) {
        guard let handle = handle else { return }
        moreAction?(handle, button)
    }
}
