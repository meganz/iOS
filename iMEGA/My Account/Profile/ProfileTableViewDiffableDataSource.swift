import MEGAFoundation
import MEGAL10n
import MEGASDKRepo
import UIKit

final class ProfileTableViewDiffableDataSource: UITableViewDiffableDataSource<ProfileSection, ProfileSectionRow> {

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch snapshot().sectionIdentifiers[section] {
        case .security:
            return Strings.Localizable.recoveryKey
        case .plan:
            return Strings.Localizable.plan
        case .session, .profile, .subscription:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch snapshot().sectionIdentifiers[section] {
        case .security:
            return Strings.Localizable.ifYouLoseThisRecoveryKeyAndForgetYourPasswordBAllYourFilesFoldersAndMessagesWillBeInaccessibleEvenByMEGAB.replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "")
        case .plan:
            guard let accountDetails = MEGASdk.shared.mnz_accountDetails else {
                return nil
            }
            var planFooterString = ""
            
            if accountDetails.type != .free {
                if accountDetails.subscriptionRenewTime > 0 {
                    let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.subscriptionRenewTime))
                    planFooterString = Strings.Localizable.renewsOn + " " + expiryDateFormatterOfProfessionalAccountExpiryDate(renewDate).localisedString(from: renewDate)
                } else if accountDetails.proExpiration > 0 &&
                            accountDetails.type != .business &&
                            accountDetails.type != .proFlexi {
                    let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.proExpiration))
                    planFooterString = Strings.Localizable.expiresOn(expiryDateFormatterOfProfessionalAccountExpiryDate(renewDate).localisedString(from: renewDate))
                }
            }
            return planFooterString
        case .session:
            if FileManager.default.mnz_existsOfflineFiles() && MEGASdk.shared.transfers.size != 0 {
                return Strings.Localizable.whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDeviceAndOngoingTransfersWillBeCancelled
            } else if FileManager.default.mnz_existsOfflineFiles() {
                return Strings.Localizable.whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDevice
            } else if MEGASdk.shared.transfers.size != 0 {
                return Strings.Localizable.whenYouLogoutOngoingTransfersWillBeCancelled
            } else {
                return nil
            }
        case .profile, .subscription:
            return nil
        }
    }
    
    private func expiryDateFormatterOfProfessionalAccountExpiryDate(_ expiryDate: Date) -> any DateFormatting {
        let calendar = Calendar.current
        let startingOfToday = Date().startOfDay(on: calendar)
        guard let daysOfDistance = startingOfToday?.dayDistance(toFutureDate: expiryDate,
                                                                on: Calendar.current) else {
                                                                    return DateFormatter.dateMedium()
        }
        let numberOfDaysAWeek = 7
        if daysOfDistance > numberOfDaysAWeek {
            return DateFormatter.dateMedium()
        }

        if expiryDate.isToday(on: calendar) || expiryDate.isTomorrow(on: calendar) {
            return DateFormatter.dateRelativeMedium()
        }

        return DateFormatter.dateMediumWithWeekday()
    }
}
