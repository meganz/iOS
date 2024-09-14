import MEGADesignToken
import MEGAL10n
import UIKit

final class BadgeButton: UIButton {

    // MARK: - Subviews

    private var badgeLabel: PaddingLabel?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView(with: traitCollection)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView(with: traitCollection)
    }

    // MARK: - Publics

    func setBadgeText(_ text: String?) {
        accessibilityLabel = Strings.Localizable.myAccount
        guard let text, !text.isEmpty else {
            badgeLabel?.isHidden = true
            accessibilityValue = nil
            return
        }
        badgeLabel?.isHidden = false
        badgeLabel?.text = text
        badgeLabel?.font = UIFont.boldSystemFont(ofSize: 12.0)
        badgeLabel?.edgeInsets = UIEdgeInsets(top: 4, left: 2, bottom: 4, right: 2)
        badgeLabel?.layer.cornerRadius = 10
        accessibilityValue = Strings.Localizable.notifications
        
        if let badgeLabel {
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: calculateWidthThatFits(label: badgeLabel)).isActive = true
        }
    }
    
    func setAvatarImage(_ avatarImage: UIImage) {
        setImage(avatarImage, for: .normal)
        setBackgroundImage(nil, for: .normal)
    }

    // MARK: - Privates

    private func layoutBadgeLabel(_ badgeLabel: UILabel) {
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }

    private func setupBadgeLabel(with trait: UITraitCollection) -> UILabel {
        let badgeLabel = PaddingLabel()
        layoutBadgeLabel(badgeLabel)

        badgeLabel.backgroundColor = TokenColors.Components.interactive
        badgeLabel.textColor = TokenColors.Text.onColor
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        self.badgeLabel = badgeLabel
        
        return badgeLabel
    }

    private func setupView(with trait: UITraitCollection) {
        translatesAutoresizingMaskIntoConstraints = false
        let badgeLabel = setupBadgeLabel(with: trait)
        badgeLabel.isHidden = true

        let backgroundImageRect = CGRect(origin: .zero, size: CGSize(width: 28, height: 28))
        let backgroudImage = UIImage(color: UIColor.mnz_tertiaryGray(for: trait), andBounds: backgroundImageRect).withRoundedCorners(radius: 14)
        
        setBackgroundImage(backgroudImage, for: .normal)
        addSubview(badgeLabel)

        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: topAnchor),
            badgeLabel.centerXAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func calculateWidthThatFits(label: UILabel) -> CGFloat {
        let minimumWidth: CGFloat = 20
        let fitSize = CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
        let fitWidth = label.sizeThatFits(fitSize).width
        return fitWidth > minimumWidth ? fitWidth : minimumWidth
    }
}
