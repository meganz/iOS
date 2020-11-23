import UIKit

final class BadgeButton: UIButton {

    // MARK: - Subviews

    private var badgeLabel: UILabel?

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
        guard let text = text, !text.isEmpty else {
            badgeLabel?.isHidden = true
            return
        }
        badgeLabel?.isHidden = false
        badgeLabel?.text = text
    }

    // MARK: - Privates

    private func layoutBadgeLabel(_ badgeLabel: UILabel) {
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeLabel.widthAnchor.constraint(equalToConstant: 20),
            badgeLabel.heightAnchor.constraint(equalTo: badgeLabel.widthAnchor)
        ])
    }

    private func setupBadgeLabel(with trait: UITraitCollection) -> UILabel {
        let badgeLabel = UILabel()
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
        addSubview(badgeLabel)

        NSLayoutConstraint.activate([
            badgeLabel.topAnchor.constraint(equalTo: topAnchor),
            badgeLabel.centerXAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
