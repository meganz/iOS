import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

extension AchievementsDetailsViewController {
    @objc func showAddPhoneNumber() {
        let router = SMSVerificationViewRouter(
            verificationType: .addPhoneNumber,
            presenter: self,
            onPhoneNumberVerified: { [weak self] in
                MEGASdk.shared.getAccountAchievements(with: RequestDelegate { result in
                    switch result {
                    case .success(let request):
                        guard let self, let megaAchievementsDetails = request.megaAchievementsDetails else { return }
                        self.achievementsDetails = megaAchievementsDetails
                        for i in 0...megaAchievementsDetails.rewardsCount where megaAchievementsDetails.awardClass(at: UInt(i)) == MEGAAchievement.addPhone.rawValue {
                            self.completedAchievementIndex = NSNumber(integerLiteral: i)
                            self.setupView()
                            self.onAchievementDetailsUpdated?(megaAchievementsDetails)
                            return
                        }
                    case .failure:
                        break
                    }
                })
            }
        )

        router.start()
    }

    @objc func setupView() {
        if let completedAchievementIndex = completedAchievementIndex {
            setupCompletedAchievementDetail(completedAchievementIndex: UInt(truncating: completedAchievementIndex))
        } else {
            setupIncompletedAchivementDetail()
        }
        setupLabelsLayout()
    }

    private func setupLabelsLayout() {
        howItWorksLabel?.textAlignment = .center
        howItWorksExplanationLabel?.textAlignment = .center
        setLineHeight(howItWorksExplanationLabel, lineHeight: 30)
    }

    private func setLineHeight(_ label: UILabel?, lineHeight: CGFloat) {
        guard let label, let labelText = label.text else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.alignment = label.textAlignment

        let attributedString = NSMutableAttributedString(string: labelText)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

        if let font = label.font {
            attributedString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributedString.length))
        }

        label.attributedText = attributedString
    }

    @objc func setupColors() {
        scrollView.backgroundColor = TokenColors.Background.surface1
        view.backgroundColor = defaultBackgroundColor
        subtitleLabel?.textColor = TokenColors.Text.primary
        howItWorksTopSeparatorView.backgroundColor = TokenColors.Border.strong
        howItWorksView.backgroundColor = TokenColors.Background.surface1
        howItWorksLabel?.textColor = TokenColors.Text.primary
        howItWorksExplanationLabel?.textColor = TokenColors.Text.secondary
        addPhoneNumberButton?.mnz_setupPrimary()
    }

    @objc func setupCompletedAchievementDetail(completedAchievementIndex: UInt) {
        guard let achievementsDetails = achievementsDetails else { return }

        let awardId = achievementsDetails.awardId(at: completedAchievementIndex)
        let storageRewardString = String.memoryStyleString(fromByteCount: achievementsDetails.rewardStorage(byAwardId: awardId))

        var howItWorksCompletedExplanation = ""

        switch achievementClass {
        case .welcome:
            howItWorksCompletedExplanation = Strings.Localizable.Account.Achievement.Registration.Explanation.label(storageRewardString)
        case .desktopInstall:
            howItWorksCompletedExplanation = Strings.Localizable.Account.Achievement.DesktopApp.Complete.Explaination.label(storageRewardString)
        case .mobileInstall:
            howItWorksCompletedExplanation = Strings.Localizable.Account.Achievement.MobileApp.Complete.Explaination.label(storageRewardString)
        case .addPhone:
            howItWorksCompletedExplanation = Strings.Localizable.Account.Achievement.PhoneNumber.Complete.Explaination.label(storageRewardString)
            updateAddPhoneNumberStatus(isHidden: true)
        case .vpnFreeTrial:
            howItWorksCompletedExplanation = Strings.Localizable.Account.Achievement.VpnFreeTrial.Complete.Explanation.label(storageRewardString)
        case .passFreeTrial:
            howItWorksCompletedExplanation = Strings.Localizable.Account.Achievement.PassFreeTrial.Complete.Explanation.label(storageRewardString)
        default:
            break
        }

        howItWorksExplanationLabel?.text = howItWorksCompletedExplanation
        setupBonusExpireInLabelTextSwift(completedAchievementIndex: completedAchievementIndex)
    }

    @objc func setupIncompletedAchivementDetail() {
        guard let achievementsDetails else { return }

        self.subtitleView?.layer.borderWidth = 0

        let storageString = storageString(achievementsDetails: achievementsDetails)
        let validityString = validityString(achievementsDetails: achievementsDetails)
        let validitySubstring = validitySubstring(achievementsDetails: achievementsDetails)

        self.subtitleLabel?.text = Strings.Localizable.Account.Achievement.Incomplete.subtitle(storageString, validityString)
        self.howItWorksLabel?.text = Strings.Localizable.howItWorks

        var howItWorksExplanation = ""

        switch achievementClass {
        case .desktopInstall:
            howItWorksExplanation = Strings.Localizable.Account.Achievement.DesktopApp.Incomplete.Explaination.label(storageString, validitySubstring)
        case .mobileInstall:
            howItWorksExplanation = Strings.Localizable.Account.Achievement.MobileApp.Incomplete.Explaination.label(storageString, validitySubstring)
        case .addPhone:
            updateAddPhoneNumberStatus(isHidden: false)
            howItWorksExplanation = Strings.Localizable.Account.Achievement.PhoneNumber.Incomplete.Explaination.label(storageString, validitySubstring)
        case .vpnFreeTrial:
            subtitleLabel?.text = Strings.Localizable.Account.Achievement.VpnFreeTrial.Detail.Incomplete.label(storageString, validityString)
            howItWorksExplanation = Strings.Localizable.Account.Achievement.VpnFreeTrial.Incomplete.Explanation.label
            addInstallButton(title: Strings.Localizable.Account.Achievement.VpnFreeTrial.buttonText, action: MEGALinkManager.openVPNApp)
        case .passFreeTrial:
            subtitleLabel?.text = Strings.Localizable.Account.Achievement.PassFreeTrial.Detail.Incomplete.label(storageString, validityString)
            howItWorksExplanation = Strings.Localizable.Account.Achievement.PassFreeTrial.Incomplete.Explanation.label
            addInstallButton(title: Strings.Localizable.Account.Achievement.PassFreeTrial.buttonText, action: MEGALinkManager.openPWMApp)
        default:
            break
        }

        howItWorksExplanationLabel?.text = howItWorksExplanation
    }

    @objc func setupBonusExpireInLabelTextSwift(completedAchievementIndex: UInt) {
        guard let achievementsDetails = achievementsDetails,
              let awardExpirationDate = achievementsDetails.awardExpiration(at: completedAchievementIndex)
        else { return }

        var bonusExpiresIn = ""

        let storageString = storageString(achievementsDetails: achievementsDetails)
        let validityString = validityString(achievementsDetails: achievementsDetails)

        switch achievementClass {
        case .vpnFreeTrial:
            bonusExpiresIn = Strings.Localizable.Account.Achievement.FreeTrial.Detail.Complete.label(storageString, validityString)
            subtitleLabel?.textColor = TokenColors.Text.secondary
            subtitleView?.backgroundColor = TokenColors.Background.surface1
            subtitleView?.layer.borderColor = TokenColors.Border.strong.cgColor
            addInstallButton(title: Strings.Localizable.Account.Achievement.VpnFreeTrial.buttonText, state: .disabled)
        case .passFreeTrial:
            bonusExpiresIn = Strings.Localizable.Account.Achievement.FreeTrial.Detail.Complete.label(storageString, validityString)
            subtitleLabel?.textColor = TokenColors.Text.secondary
            subtitleView?.backgroundColor = TokenColors.Background.surface1
            subtitleView?.layer.borderColor = TokenColors.Border.strong.cgColor
            addInstallButton(title: Strings.Localizable.Account.Achievement.PassFreeTrial.buttonText, state: .disabled)
        default:
            let daysUntilExpiration = Date().dayDistance(toFutureDate: awardExpirationDate, on: .autoupdatingCurrent) ?? 0

            if daysUntilExpiration == 0 {
                bonusExpiresIn = Strings.Localizable.expired
                subtitleLabel?.textColor = TokenColors.Text.warning
                subtitleView?.layer.borderColor = TokenColors.Support.warning.cgColor
            } else {
                bonusExpiresIn = Strings.Localizable.Account.Achievement.Complete.ValidBonusExpiry.Detail.subtitle(daysUntilExpiration)
                subtitleView?.layer.borderColor = TokenColors.Border.subtle.cgColor
            }
        }

        subtitleLabel?.text = bonusExpiresIn
    }

    private func storageString(achievementsDetails: MEGAAchievementsDetails) -> String {
        let classId = Int(self.achievementClass.rawValue)
        return String.memoryStyleString(fromByteCount: achievementsDetails.classStorage(forClassId: classId))
    }

    private func validityString(achievementsDetails: MEGAAchievementsDetails) -> String {
        let classId = Int(self.achievementClass.rawValue)
        let rewardDuration = achievementsDetails.classExpire(forClassId: classId)
        return rewardDuration > 0
            ? Strings.Localizable.Account.Achievement.Validity.days(rewardDuration)
            : Strings.Localizable.Account.Achievement.Validity.permanent
    }

    private func validitySubstring(achievementsDetails: MEGAAchievementsDetails) -> String {
        let classId = Int(self.achievementClass.rawValue)
        let rewardDuration = achievementsDetails.classExpire(forClassId: classId)
        return rewardDuration > 0
            ? Strings.Localizable.Account.Achievement.Validity.Substring.days(rewardDuration)
            : Strings.Localizable.Account.Achievement.Validity.Substring.permanent
    }

    // MARK: - VPN & PWM Free Trial

    private func addInstallButton(title: String, state: MEGAButtonState = .default, action: (() -> Void)? = nil) {
        let installButton = MEGAButton(title, state: state, action: action).padding(.bottom, 40)
        let hostingController = UIHostingController(rootView: installButton)
        let hostedView = hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear
        howItWorksView.addArrangedSubview(hostedView)
        addChild(hostingController)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: howItWorksView.leadingAnchor, constant: 20),
            hostedView.trailingAnchor.constraint(equalTo: howItWorksView.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Token Colors

    @objc var defaultBackgroundColor: UIColor {
        TokenColors.Background.page
    }

    private func updateAddPhoneNumberStatus(isHidden: Bool) {
        addPhoneNumberButton?.isHidden = isHidden
    }
}
