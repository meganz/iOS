import MEGAFoundation
import MEGAL10n
import MEGASDKRepo
import UIKit

final class ProfileTableViewDiffableDataSource: UITableViewDiffableDataSource<ProfileSection, ProfileSectionRow> {

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return switch snapshot().sectionIdentifiers[section] {
        case .security: Strings.Localizable.recoveryKey
        case .plan: Strings.Localizable.plan
        case .session, .profile, .subscription: nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return switch snapshot().sectionIdentifiers[section] {
        case .security: Strings.Localizable.ifYouLoseThisRecoveryKeyAndForgetYourPasswordBAllYourFilesFoldersAndMessagesWillBeInaccessibleEvenByMEGAB.replacingOccurrences(of: "[B]", with: "").replacingOccurrences(of: "[/B]", with: "")
        case .plan: planFooterTitle()
        case .session: sessionFooterTitle()
        case .profile, .subscription: nil
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
    
    private func planFooterTitle() -> String? {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails,
              accountDetails.type != .free else {
            return nil
        }
        if accountDetails.subscriptionRenewTime > 0 {
            let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.subscriptionRenewTime))
            return Strings.Localizable.renewsOn + " " + expiryDateFormatterOfProfessionalAccountExpiryDate(renewDate).localisedString(from: renewDate)
        } else if accountDetails.proExpiration > 0 &&
                    accountDetails.type != .business &&
                    accountDetails.type != .proFlexi {
            let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.proExpiration))
            return Strings.Localizable.expiresOn(expiryDateFormatterOfProfessionalAccountExpiryDate(renewDate).localisedString(from: renewDate))
        }
        
        return nil
    }
    
    private func sessionFooterTitle() -> String? {
        if FileManager.default.mnz_existsOfflineFiles() && MEGASdk.shared.transfers.size != 0 {
            return Strings.Localizable.whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDeviceAndOngoingTransfersWillBeCancelled
        } else if FileManager.default.mnz_existsOfflineFiles() {
            return Strings.Localizable.whenYouLogoutFilesFromYourOfflineSectionWillBeDeletedFromYourDevice
        } else if MEGASdk.shared.transfers.size != 0 {
            return Strings.Localizable.whenYouLogoutOngoingTransfersWillBeCancelled
        }
        
        return nil
    }
}
