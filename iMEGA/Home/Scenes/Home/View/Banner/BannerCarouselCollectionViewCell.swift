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

    override func awakeFromNib() {
        super.awakeFromNib()
        bannerView.layer.cornerRadius = 10
        bannerView.layer.masksToBounds = true

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
}

// MARK: - TraitEnviromentAware

extension BannerCarouselCollectionViewCell: TraitEnviromentAware {

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
