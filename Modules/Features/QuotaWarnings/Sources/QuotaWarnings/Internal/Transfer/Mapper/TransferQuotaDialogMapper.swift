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

    func header(accountDetails: AccountDetailsEntity?, canUpgrade: Bool) -> QuotaDialogHeader {
        QuotaDialogHeader(
            image: MEGAAssets.Image.quotaWarning,
            title: title(accountDetails: accountDetails),
            subtitle: .attributed(
                text: subtitleText(canUpgrade: canUpgrade),
                links: [canUpgrade ? learnMoreAttribute : megaIoLinkAttribute]
            )
        )
    }

    /// `nil` for a free user as there is no public transfer quota for free user
    func currentPlan(accountDetails: AccountDetailsEntity) -> CurrentPlan? {
        guard let quota = currentQuotaProgress(accountDetails: accountDetails) else { return nil }

        return CurrentPlan(
            name: planName(accountDetails: accountDetails),
            quota: quota
        )
    }

    func recommendedPlan(_ plan: RecommendedUpgradePlanEntity, accountDetails: AccountDetailsEntity?) -> RecommendedPlan {
        if let accountDetails, !accountDetails.isFree {
            let quotaProgress = QuotaProgress(
                status: .good,
                usedBytes: accountDetails.transferUsed,
                totalBytes: plan.transferLimit.gigabytesToBytes()
            )
            return makeRecommendedPlan(plan, quotaProgress: quotaProgress)
        } else {
            return makeRecommendedPlan(plan, quotaProgress: nil)
        }
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

    private func title(accountDetails: AccountDetailsEntity?) -> String {
        switch severity {
        case .limitedDownload, .limitedStreaming:
            if let accountDetails, let quota = currentQuotaProgress(accountDetails: accountDetails) {
                Strings.Localizable.QuotaWarning.Transfer.PercentUsed.title(quota.usedPercentage)
            } else {
                Strings.Localizable.QuotaWarning.Transfer.RunningLow.title
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

    private func currentQuotaProgress(accountDetails: AccountDetailsEntity) -> QuotaProgress? {
        /// `nil` for a free user as there is no public transfer quota for free user
        guard !accountDetails.isFree else { return nil }
        
        let status: QuotaStatus = switch severity {
        case .limitedDownload, .limitedStreaming: .almostFull
        case .downloadExceeded, .streamingExceeded: .full
        }

        return QuotaProgress(
            status: status,
            usedBytes: accountDetails.transferUsed,
            totalBytes: accountDetails.transferMax
        )
    }
}
