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
        badgeLabel?.edgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        badgeLabel?.layer.cornerRadius = 10
        accessibilityValue = Strings.Localizable.notifications
    }

    // MARK: - Privates

    private func layoutBadgeLabel(_ badgeLabel: UILabel) {
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badgeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func setupBadgeLabel(with trait: UITraitCollection) -> UILabel {
        let badgeLabel = PaddingLabel()
        layoutBadgeLabel(badgeLabel)

        let labelStyler = trait.theme.labelStyleFactory.styler(of: .badge)
        labelStyler(badgeLabel)

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
}
