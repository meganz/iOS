import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGAUIComponent

extension QuotaDialogViewModel {
    func currentStorageQuotaProgress(severity: StorageQuotaSeverity, accountDetailsEntity: AccountDetailsEntity) -> QuotaProgress {
        let status: QuotaStatus = switch severity {
        case .almostFull:
                .almostFull
        case .full:
                .full
        }
        
        return QuotaProgress(
            status: status,
            usedBytes: accountDetailsEntity.storageUsed,
            totalBytes: accountDetailsEntity.storageMax,
            style: .usedOfTotal
        )
    }
    
    func recommendedStorageQuotaProgress(accountDetailsEntity: AccountDetailsEntity, planEntity: PlanEntity) -> QuotaProgress {
        QuotaProgress(
            status: .good,
            usedBytes: accountDetailsEntity.storageUsed,
            totalBytes: planEntity.storageLimit.gigabytesToBytes(),
            style: .usedOfTotal
        )
    }
    
    func storageCurrentPlan(severity: StorageQuotaSeverity, accountDetailsEntity: AccountDetailsEntity) -> CurrentPlan {
        CurrentPlan(
            name: accountDetailsEntity.proLevel.toAccountTypeDisplayName(),
            quota: currentStorageQuotaProgress(severity: severity, accountDetailsEntity: accountDetailsEntity)
        )
    }
    
    func storageRecommendedPlan(accountDetailsEntity: AccountDetailsEntity, planEntity: PlanEntity) -> RecommendedPlan {
        let planPrice = subscriptionPlanPriceUseCase.planPrice(for: planEntity)
        return RecommendedPlan(
            name: planEntity.name,
            ribbonText: planEntity.ribbonText(for: planPrice),
            price: RecommendedPlanPriceMapper().map(planPrice),
            storageText: Strings.Localizable.SubscriptionPurchase.Plan.storage(planEntity.storage),
            transferText: Strings.Localizable.SubscriptionPurchase.Plan.transfer(planEntity.transfer),
            quotaProgress: recommendedStorageQuotaProgress(accountDetailsEntity: accountDetailsEntity, planEntity: planEntity)
        )
    }
}
