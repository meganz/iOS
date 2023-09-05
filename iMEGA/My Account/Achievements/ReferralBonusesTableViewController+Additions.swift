import MEGAL10n

extension ReferralBonusesTableViewController {
    @objc func awardDaysLeftMessage(_ remainingDays: Int) -> String {
        return Strings.Localizable.Account.Achievement.Complete.ValidDays.subtitle(remainingDays)
    }
}
