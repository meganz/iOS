import MEGAAssets
import MEGAUIKit
import UIKit

final class BannerCarouselCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var bannerView: UIView!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var dismissButton: UIButton!

    private var bannerIdentifier: Int?
    private var dismissAction: ((Int) -> Void)?
    
    private static let sizingCell = UINib(nibName: "\(BannerCarouselCollectionViewCell.self)", bundle: nil).instantiate(withOwner: nil, options: nil).first as? BannerCarouselCollectionViewCell

    override func awakeFromNib() {
        super.awakeFromNib()
        bannerView.layer.cornerRadius = 10
        bannerView.layer.masksToBounds = true
        dismissButton.setImage(MEGAAssets.UIImage.image(named: "closeBanner"), for: .normal)
        dismissButton.addTarget(self, action: .didTapDismissButton, for: .touchUpInside)
    }

    func configure(with banner: MEGABannerView.Banner) {
        iconImageView.sd_setImage(with: banner.iconImage)
        backgroundImageView.sd_setImage(with: banner.backgroundImage)
        titleLabel.text = banner.title
        subtitleLabel.text = banner.detail
        bannerIdentifier = banner.identifier
        dismissAction = banner.dismissAction

        style(with: traitCollection)
    }

    private func style(with trait: UITraitCollection) {
        trait.theme.labelStyleFactory.styler(of: .homeBannerTitle)(titleLabel)
        trait.theme.labelStyleFactory.styler(of: .homeBannerSubtitle)(subtitleLabel)
    }

    @objc fileprivate func didTapDismissButton() {
        guard let bannerIdentifier = bannerIdentifier else { return }
        dismissAction?(bannerIdentifier)
    }
    
    public static func height(_ banner: MEGABannerView.Banner, width: CGFloat) -> CGFloat {
        sizingCell?.prepareForReuse()
        sizingCell?.configure(with: banner)
        sizingCell?.layoutIfNeeded()
        
        var fittingSize = UIView.layoutFittingCompressedSize
        fittingSize.width = width
        let size = sizingCell?.contentView.systemLayoutSizeFitting(fittingSize,
                                                                   withHorizontalFittingPriority: .required,
                                                                   verticalFittingPriority: .defaultLow)
        
        return size?.height ?? 0.0
    }
}

// MARK: - TraitEnvironmentAware

extension BannerCarouselCollectionViewCell: TraitEnvironmentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        style(with: currentTrait)
    }
}

private extension Selector {
    static let didTapDismissButton = #selector(BannerCarouselCollectionViewCell.didTapDismissButton)
}
