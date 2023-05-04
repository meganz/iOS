import MEGAData

extension AchievementsDetailsViewController {
    @objc func showAddPhoneNumber() {
        let router = SMSVerificationViewRouter(
            verificationType: .addPhoneNumber,
            presenter: self,
            onPhoneNumberVerified: { [weak self] in
                MEGASdk.shared.getAccountAchievements(with: RequestDelegate { result in
                    switch result {
                    case .success(let request):
                        guard let self = self else { return }
                        self.achievementsDetails = request.megaAchievementsDetails
                        for i in 0...request.megaAchievementsDetails.rewardsCount where request.megaAchievementsDetails.awardClass(at: UInt(i)) == MEGAAchievement.addPhone.rawValue {
                            self.completedAchievementIndex = NSNumber(integerLiteral: i)
                            self.setupView()
                            self.onAchievementDetailsUpdated?(request.megaAchievementsDetails)
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
            self.addPhoneNumberButton?.isHidden = true
        default:
            break
        }

        howItWorksExplanationLabel?.text = howItWorksCompletedExplanation
        setupBonusExpireInLabelTextSwift(completedAchievementIndex: completedAchievementIndex)
    }

    @objc func setupIncompletedAchivementDetail() {
        guard let achievementsDetails = achievementsDetails else { return }

        self.subtitleView?.layer.borderWidth = 0

        let storageString = String.memoryStyleString(fromByteCount: achievementsDetails.classStorage(forClassId: Int(self.achievementClass.rawValue)))
        self.subtitleLabel?.text = Strings.Localizable.Account.Achievement.Incomplete.subtitle(storageString)
        self.howItWorksLabel?.text = Strings.Localizable.howItWorks

        var howItWorksExplanation = ""

        switch achievementClass {
        case .desktopInstall:
            howItWorksExplanation = Strings.Localizable.Account.Achievement.DesktopApp.Incomplete.Explaination.label(storageString)
        case .mobileInstall:
            howItWorksExplanation = Strings.Localizable.Account.Achievement.MobileApp.Incomplete.Explaination.label(storageString)
        case .addPhone:
            self.addPhoneNumberButton?.isHidden = false
            howItWorksExplanation = Strings.Localizable.Account.Achievement.PhoneNumber.Incomplete.Explaination.label(storageString)
        default:
            break
        }

        howItWorksExplanationLabel?.text = howItWorksExplanation
    }

    @objc func setupBonusExpireInLabelTextSwift(completedAchievementIndex: UInt) {
        guard let achievementsDetails = achievementsDetails,
              let awardExpirationDate = achievementsDetails.awardExpiration(at: completedAchievementIndex)
        else { return }

        let daysUntilExpiration = Date().dayDistance(toFutureDate: awardExpirationDate, on: .autoupdatingCurrent) ?? 0

        var bonusExpiresIn = ""

        if daysUntilExpiration == 0 {
            bonusExpiresIn = Strings.Localizable.expired
            subtitleLabel?.textColor = UIColor.mnz_red(for: self.traitCollection)
            subtitleView?.layer.borderColor = UIColor.mnz_red(for: self.traitCollection).cgColor
        } else {
            bonusExpiresIn = Strings.Localizable.Account.Achievement.Complete.Valid.Detail.subtitle(daysUntilExpiration)
            subtitleView?.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.14).cgColor
        }

        subtitleLabel?.text = bonusExpiresIn
    }
}
