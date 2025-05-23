import MEGAAppPresentation
import MEGAL10n

extension AchievementsViewController {
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
    }
    
    @objc
    func configureBackButton() {
        setMenuCapableBackButtonWith(menuTitle: Strings.Localizable.achievementsTitle)
    }
    
    @objc func achievementSubtitle(remainingDays: Int) -> String {
        guard remainingDays > 0 else {
            return Strings.Localizable.expired
        }
        return Strings.Localizable.Account.Achievement.Complete.ValidDays.subtitle(remainingDays)
    }
}

// MARK: - BottomOverlayPresenterProtocol

extension AchievementsViewController: BottomOverlayPresenterProtocol {
    public func updateContentView(_ height: CGFloat) {
        additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: height, right: 0)
    }
    
    public func hasUpdatedContentView() -> Bool {
        additionalSafeAreaInsets.bottom != 0
    }
}
