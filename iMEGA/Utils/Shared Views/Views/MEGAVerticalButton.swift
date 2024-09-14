import MEGADesignToken

final class MEGAVerticalButton: UIButton {
    private var badgeView: UIView?
    private var badgeLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel?.adjustsFontForContentSizeCategory = true
    }
    
    // MARK: - Badge
    @objc func setBadgeCount(value: String) {
        guard !value.isEmpty else {
            badgeView?.isHidden = true
            return
        }
        
        if badgeView == nil {
            setupBadgeView()
        }
        
        badgeView?.isHidden = false
        badgeLabel?.text = value
    }
    
    private func setupBadgeView() {
        guard badgeView == nil, let imageView else { return }
        
        let badgeView = UIView()
        badgeView.backgroundColor = TokenColors.Components.interactive
        badgeView.clipsToBounds = true
        badgeView.layer.cornerRadius = 9
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeView)
        self.badgeView = badgeView
        
        let badgeLabel = UILabel()
        badgeLabel.textColor = UIColor.whiteFFFFFF
        badgeLabel.font = UIFont.systemFont(ofSize: 11)
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.badgeView?.addSubview(badgeLabel)
        self.badgeLabel = badgeLabel
        
        NSLayoutConstraint.activate([
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            badgeView.heightAnchor.constraint(equalToConstant: 18),
            badgeView.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: 14),
            badgeView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: (imageView.frame.width / 2) + 16),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 4),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -4),
            badgeLabel.topAnchor.constraint(equalTo: badgeView.topAnchor, constant: 2),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: -2)
        ])
    }
}
