import Foundation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAInfrastructure
import MEGAL10n
import MEGASwift
import MEGAUIComponent
import SwiftUI

struct TransferQuotaDialogMapper: QuotaDialogMapping {
    private let severity: TransferQuotaSeverity

    private let learnMoreTitle = Strings.Localizable.learnMore
    private let learnMoreURL = URL(string: "https://help.mega.io/plans-storage/space-storage/transfer-quota")!

    init(severity: TransferQuotaSeverity) {
        self.severity = severity
    }

    func header(accountDetails: AccountDetailsEntity, canUpgrade: Bool) -> QuotaDialogHeader {
        QuotaDialogHeader(
            image: MEGAAssets.Image.quotaWarning,
            title: title(accountDetails: accountDetails),
            subtitle: .attributed(
                text: subtitleText(canUpgrade: canUpgrade),
                links: [canUpgrade ? learnMoreAttribute : megaIoLinkAttribute]
            )
        )
    }

    func currentPlan(accountDetails: AccountDetailsEntity) -> CurrentPlan {
        CurrentPlan(
            name: accountDetails.proLevel.toAccountTypeDisplayName(),
            quota: currentQuotaProgress(accountDetails: accountDetails)
        )
    }

    func recommendedPlan(_ plan: RecommendedUpgradePlanEntity, accountDetails: AccountDetailsEntity) -> RecommendedPlan {
        let quotaProgress = QuotaProgress(
            status: .good,
            usedBytes: accountDetails.transferUsed,
            totalBytes: plan.transferLimit.gigabytesToBytes(),
            style: .usedOfTotal
        )
        return makeRecommendedPlan(plan, quotaProgress: quotaProgress)
    }

    // MARK: - Private

    private var learnMoreAttribute: SubstringAttribute {
        var attributes = AttributeContainer()
        attributes.underlineStyle = .single
        attributes.font = .callout.weight(.regular)
        attributes.foregroundColor = TokenColors.Text.primary.swiftUI
        return SubstringAttribute(
            text: learnMoreTitle,
            attributes: attributes,
            action: { DependencyInjection.externalLinkOpener.openExternalLink(with: learnMoreURL) }
        )
    }

    private func title(accountDetails: AccountDetailsEntity) -> String {
        switch severity {
        case .limitedDownload, .limitedStreaming:
            if accountDetails.isFree {
                Strings.Localizable.QuotaWarning.Transfer.RunningLow.title
            } else {
                Strings.Localizable.QuotaWarning.Transfer.PercentUsed.title(
                    currentQuotaProgress(accountDetails: accountDetails).usedPercentage
                )
            }
        case .downloadExceeded, .streamingExceeded:
            Strings.Localizable.QuotaWarning.Transfer.Exceeded.title
        }
    }

    private func subtitleText(canUpgrade: Bool) -> String {
        switch severity {
        case .limitedDownload:
            canUpgrade
                ? Strings.Localizable.QuotaWarning.Transfer.LimitedDownload.subtitle(learnMoreTitle)
                : Strings.Localizable.QuotaWarning.Transfer.LimitedDownload.Manage.subtitle(megaIoLinkText)
        case .limitedStreaming:
            canUpgrade
                ? Strings.Localizable.QuotaWarning.Transfer.LimitedStreaming.subtitle(learnMoreTitle)
                : Strings.Localizable.QuotaWarning.Transfer.LimitedStreaming.Manage.subtitle(megaIoLinkText)
        case .downloadExceeded:
            canUpgrade
                ? Strings.Localizable.QuotaWarning.Transfer.DownloadExceeded.subtitle(learnMoreTitle)
                : Strings.Localizable.QuotaWarning.Transfer.DownloadExceeded.Manage.subtitle(megaIoLinkText)
        case .streamingExceeded:
            canUpgrade
                ? Strings.Localizable.QuotaWarning.Transfer.StreamingExceeded.subtitle(learnMoreTitle)
                : Strings.Localizable.QuotaWarning.Transfer.StreamingExceeded.Manage.subtitle(megaIoLinkText)
        }
    }

    private func currentQuotaProgress(accountDetails: AccountDetailsEntity) -> QuotaProgress {
        let status: QuotaStatus = switch severity {
        case .limitedDownload, .limitedStreaming: .almostFull
        case .downloadExceeded, .streamingExceeded: .full
        }

        /// Bcause transfer quota limit is not available for free user,
        /// Hardcode the total bytes such that the used percentage is 100% for full, otherwise 80%
        let totalBytes = if accountDetails.isFree {
            if status == .full {
                Int64(100)
            } else {
                Int64(Double(accountDetails.transferUsed) * 1.25)
            }
        } else {
            accountDetails.transferMax
        }
        
        /// Displayed the used transfer quota only because transfer quota limit is not available.
        let style: QuotaUsageStyle = if accountDetails.isFree {
            .usedOnly
        } else {
            .usedOfTotal
        }
        
        return QuotaProgress(
            status: status,
            usedBytes: accountDetails.transferUsed,
            totalBytes: totalBytes,
            style: style
        )
    }
}
