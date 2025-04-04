import MEGAAppSDKRepo
import MEGAFoundation
import MEGAL10n
import UIKit

final class ProfileTableViewDiffableDataSource: UITableViewDiffableDataSource<ProfileSection, ProfileSectionRow> {
    lazy var calendar: Calendar = {
        Calendar.current
    }()
    
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
    
    private func dateFormatterForDate(_ date: Date) -> any DateFormatting {
        let startOfToday = calendar.startOfDay(for: Date())
        let daysDifference = calendar.dateComponents([.day], from: startOfToday, to: date).day ?? Int.max
        
        // If the date is within a week, return a medium style with weekday; otherwise use a standard medium style.
        if abs(daysDifference) <= 7 {
            return DateFormatter.dateMediumWithWeekday()
        } else {
            return DateFormatter.dateMedium()
        }
    }

    private func planFooterTitle() -> String? {
        guard
            let accountDetails = MEGASdk.shared.mnz_accountDetails,
            accountDetails.subscriptionRenewTime > 0
        else {
            return nil
        }

        let renewDate = Date(timeIntervalSince1970: TimeInterval(accountDetails.subscriptionRenewTime))
        
        if renewDate.isToday(on: calendar) {
            return Strings.Localizable.Account.Profile.Renewal.today
        } else if renewDate.isTomorrow(on: calendar) {
            return Strings.Localizable.Account.Profile.Renewal.tomorrow
        } else {
            let formattedDate = dateFormatterForDate(renewDate).localisedString(from: renewDate)
            return Strings.Localizable.Account.Profile.Renewal.future(formattedDate)
        }
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
