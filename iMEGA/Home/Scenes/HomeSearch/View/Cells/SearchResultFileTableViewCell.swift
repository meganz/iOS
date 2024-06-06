import Combine
import MEGADesignToken
import MEGADomain
import MEGAUIKit
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
    
    private var viewModel: HomeSearchResultFileViewModel?
    private var subscriptions = Set<AnyCancellable>()
    private var configureCellTask: Task<Void, Never>?
    
    private var handle: HandleEntity?
    private var moreAction: ((HandleEntity, UIButton) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIColor.isDesignTokenEnabled() {
            fileNameLabel.textColor = TokenColors.Text.primary
            folderLabel.textColor = TokenColors.Text.secondary
            moreActionButton.tintColor = TokenColors.Icon.secondary
            contentView.backgroundColor = TokenColors.Background.page
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView?.image = nil
        handle = nil
        moreAction = nil
        subscriptions.removeAll()
        configureCellTask?.cancel()
        configureCellTask = nil
        viewModel = nil
    }
    
    func configure(with fileModel: HomeSearchResultFileViewModel) {
        bindViewModel(viewModel: fileModel)
        
        fileNameLabel.text = fileModel.name
        folderLabel.text = fileModel.ownerFolder
        handle = fileModel.handle
        moreAction = fileModel.moreAction
    }
    
    @objc private func didTapMoreActionButton(button: UIButton) {
        guard let handle = handle else { return }
        moreAction?(handle, button)
    }
    
    private func bindViewModel(viewModel: HomeSearchResultFileViewModel) {
        self.viewModel = viewModel
        
        subscriptions = [
            viewModel
                .$isSensitive
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.configureBlur(isSensitive: $0,
                                        hasThumbnail: viewModel.hasThumbnail)
                },
            viewModel
                .$thumbnail
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak thumbnailImageView] in
                    thumbnailImageView?.image = $0
                }
        ]
        
        configureCellTask = Task { [weak viewModel] in
            await viewModel?.configureCell()
        }
    }
    
    private func configureBlur(isSensitive: Bool, hasThumbnail: Bool) {
        [
            hasThumbnail ? nil : thumbnailImageView,
            fileNameLabel,
            folderLabel
        ].applySensitiveAlpha(isSensitive: isSensitive)
        
        if hasThumbnail, isSensitive {
            thumbnailImageView?.addBlurToView(style: .systemUltraThinMaterial)
        } else {
            thumbnailImageView?.removeBlurFromView()
        }
    }
}
