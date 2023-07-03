import MEGAData
import MEGADomain
import MEGASdk
import MEGASwift
import MEGASwiftUI
import SwiftUI

final class UpgradeAccountPlanViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private var planList: [AccountPlanEntity] = []
    private var accountDetails: AccountDetailsEntity
    
    @Published var isRestoreAccountPlan = false
    @Published var isTermsAndPoliciesPresented = false
    @Published var isDismiss = false
    @Published private(set) var currentPlan: AccountPlanEntity?
    private(set) var recommendedPlanType: AccountTypeEntity?
    
    var isShowBuyButton = false
    @Published var selectedTermTab: AccountPlanTermEntity = .yearly {
        didSet { checkSelectedPlanType() }
    }
    @Published private(set) var selectedPlanType: AccountTypeEntity? {
        didSet { toggleBuyButton() }
    }
    
    init(accountDetails: AccountDetailsEntity, purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol) {
        self.purchaseUseCase = purchaseUseCase
        self.accountDetails = accountDetails
        setupPlans()
    }
    
    // MARK: - Setup
    private func setupPlans() {
        Task {
            planList = await purchaseUseCase.accountPlanProducts()
            setRecommendedPlan()
            await setDefaultPlanTermTab()
            await setCurrentPlan(type: accountDetails.proLevel)
        }
    }
    
    private func toggleBuyButton() {
        isShowBuyButton = selectedPlanType != nil
    }
    
    @MainActor
    private func setDefaultPlanTermTab() {
        selectedTermTab = accountDetails.subscriptionCycle == .monthly ? .monthly : .yearly
    }
    
    private func checkSelectedPlanType() {
        guard let currentPlan else { return }
        
        switch accountDetails.subscriptionCycle {
        case .monthly, .yearly:
            if let selectedPlanType,
               selectedTermTab == currentPlan.term,
               selectedPlanType == currentPlan.type {
                self.selectedPlanType = nil
            }
        default: return
        }
    }

    @MainActor
    private func setCurrentPlan(type: AccountTypeEntity) {
        guard type != .free else {
            currentPlan = AccountPlanEntity(type: .free, name: AccountTypeEntity.free.toAccountTypeDisplayName())
            return
        }

        let cycle = accountDetails.subscriptionCycle
        currentPlan = planList.first { plan in
            guard cycle != .none else {
                return plan.type == type
            }
            
            let term = cycle == .monthly ? AccountPlanTermEntity.monthly : AccountPlanTermEntity.yearly
            return plan.type == type && plan.term == term
        }
        
    }

    // MARK: - Public
    var currentPlanName: String {
        currentPlan?.name ?? ""
    }
    
    var selectedPlanName: String {
        selectedPlanType?.toAccountTypeDisplayName() ?? ""
    }
    
    var filteredPlanList: [AccountPlanEntity] {
        planList.filter { $0.term == selectedTermTab }
    }
    
    var pricingPageFooterDetails: TextWithLinkDetails {
        let fullText = Strings.Localizable.UpgradeAccountPlan.Footer.Message.pricingPage
        let tappableText = fullText.subString(from: "[A]", to: "[/A]") ?? ""
        let fullTextWithoutFormatters = fullText
                                            .replacingOccurrences(of: "[A]", with: "")
                                            .replacingOccurrences(of: "[/A]", with: "")
        return TextWithLinkDetails(fullText: fullTextWithoutFormatters,
                                   tappableText: tappableText,
                                   linkString: "https://mega.nz/pro",
                                   textColor: Color(Colors.UpgradeAccount.primaryText.color),
                                   linkColor: Color(Colors.Views.turquoise.color))
    }
    
    func createAccountPlanViewModel(_ plan: AccountPlanEntity) -> AccountPlanViewModel {
        AccountPlanViewModel(
            plan: plan,
            planTag: planTag(plan),
            isSelected: isPlanSelected(plan),
            isSelectionEnabled: isSelectionEnabled(forPlan: plan),
            didTapPlan: {
                self.setSelectedPlan(plan)
            })
    }
    
    func setSelectedPlan(_ plan: AccountPlanEntity) {
        guard isSelectionEnabled(forPlan: plan) else { return }
        selectedPlanType = plan.type
    }
    
    // MARK: - Private
    private func setRecommendedPlan() {
        switch accountDetails.proLevel {
        case .free, .lite:
            recommendedPlanType = .proI
        case .proI:
            recommendedPlanType = .proII
        case .proII:
            recommendedPlanType = .proIII
        default:
            return
        }
        
        selectedPlanType = recommendedPlanType
    }
    
    private func planTag(_ plan: AccountPlanEntity) -> AccountPlanTagEntity {
        guard let currentPlan else { return .none }
        
        switch accountDetails.subscriptionCycle {
        case .none:
            if currentPlan.type == plan.type { return .currentPlan }
            if let recommendedPlanType, plan.type == recommendedPlanType { return .recommended }
        default:
            if plan == currentPlan { return .currentPlan }
            if let recommendedPlanType,
                plan.term == selectedTermTab,
                plan.type == recommendedPlanType {
                return .recommended
            }
        }
        
        return .none
    }
    
    private func isPlanSelected(_ plan: AccountPlanEntity) -> Bool {
        guard let selectedPlanType else { return false }
        return selectedPlanType == plan.type
    }
    
    private func isSelectionEnabled(forPlan plan: AccountPlanEntity) -> Bool {
        guard let currentPlan, accountDetails.subscriptionCycle != .none else {
            return true
        }
        return currentPlan != plan
    }
}
