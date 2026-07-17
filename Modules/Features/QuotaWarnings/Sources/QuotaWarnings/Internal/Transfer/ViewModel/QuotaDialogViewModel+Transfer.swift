import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGAUIComponent

extension QuotaDialogViewModel {
    func currentTransferQuotaProgress(severity: TransferQuotaSeverity, accountDetailsEntity: AccountDetailsEntity) -> QuotaProgress {
        let status: QuotaStatus = switch severity {
        case .limitedDownload:
                .almostFull
        case .downloadExceeded, .streamingExceeded:
                .full
        }

        return QuotaProgress(
            status: status,
            usedBytes: accountDetailsEntity.transferUsed,
            totalBytes: accountDetailsEntity.transferMax,
            style: accountDetailsEntity.proLevel == .free ? .usedOnly : .usedOfTotal
        )
    }

    func recommendedTransferQuotaProgress(accountDetailsEntity: AccountDetailsEntity, planEntity: PlanEntity) -> QuotaProgress {
        QuotaProgress(
            status: .good,
            usedBytes: accountDetailsEntity.transferUsed,
            totalBytes: planEntity.transferLimit.gigabytesToBytes(),
            style: .usedOfTotal
        )
    }

    func transferCurrentPlan(severity: TransferQuotaSeverity, accountDetailsEntity: AccountDetailsEntity) -> CurrentPlan {
        CurrentPlan(
            name: accountDetailsEntity.proLevel.toAccountTypeDisplayName(),
            quota: currentTransferQuotaProgress(severity: severity, accountDetailsEntity: accountDetailsEntity)
        )
    }

    func transferRecommendedPlan(accountDetailsEntity: AccountDetailsEntity, planEntity: PlanEntity) -> RecommendedPlan {
        let planPrice = subscriptionPlanPriceUseCase.planPrice(for: planEntity)
        return RecommendedPlan(
            name: planEntity.name,
            ribbonText: planEntity.ribbonText(for: planPrice),
            price: RecommendedPlanPriceMapper().map(planPrice),
            storageText: Strings.Localizable.SubscriptionPurchase.Plan.storage(planEntity.storage),
            transferText: Strings.Localizable.SubscriptionPurchase.Plan.transfer(planEntity.transfer),
            quotaProgress: recommendedTransferQuotaProgress(accountDetailsEntity: accountDetailsEntity, planEntity: planEntity)
        )
    }
}
