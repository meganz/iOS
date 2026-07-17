import MEGADesignToken
import MEGADomain
import MEGASwift
import QuotaWarnings
import SwiftUI

#if DEBUG || QA_CONFIG
/// QA-only screen for previewing the storage / transfer quota dialogs with fully configurable inputs.
///
/// Configure the **current plan** (tier + storage/transfer usage & max), pick a **scenario** (which maps
/// to a `StorageQuotaSeverity` / `TransferQuotaSeverity`), and pick the **recommended plan** (a higher
/// tier — the upgrade). Both plans are chosen as an `AccountTypeEntity`; the recommended plan's name,
/// storage, transfer and price are derived from the plan catalog. The factors are assembled into a
/// `QAQuotaDialogUseCase` (a configured `AccountDetailsEntity` + `PlanEntity`), and **Start** presents the
/// real public dialog immediately.
@MainActor
struct QuotaEventSimulatorView: View {
    // MARK: - Current plan factors
    @State private var currentTier: AccountTypeEntity = .free
    @State private var storageUsedGB: Int = 19
    @State private var storageMaxGB: Int = 20
    @State private var transferUsedGB: Int = 4
    @State private var transferMaxGB: Int = 20

    // MARK: - Scenario
    @State private var scenario: Scenario = .storageAlmostFull

    // MARK: - Recommended plan factors
    @State private var recommendedTier: AccountTypeEntity = .proI
    @State private var cycle: SubscriptionCycleEntity = .yearly
    @State private var currency: String = "EUR"

    // MARK: - Introductory offer factors
    @State private var offerType: OfferType = .none
    @State private var offerPrice: Decimal = Decimal(string: "59.88") ?? 0
    @State private var offerDuration: OfferDuration = .oneYear

    @State private var isPresentingDialog = false

    var body: some View {
        List {
            currentPlanSection
            scenarioSection
            recommendedPlanSection
            offerSection
            startSection
        }
        .listStyle(.grouped)
        .navigationTitle("Quota dialog simulator")
        .sheet(isPresented: $isPresentingDialog) {
            dialog
        }
    }

    // MARK: - Sections

    private var currentPlanSection: some View {
        Section {
            picker("Plan", selection: $currentTier, options: Self.currentTierOptions) { tierName($0) }
            picker("Storage usage", selection: $storageUsedGB, options: Self.usageSizesGB) { $0.toGBString() }
            picker("Storage max", selection: $storageMaxGB, options: Self.dataSizesGB) { $0.toGBString() }
            picker("Transfer usage", selection: $transferUsedGB, options: Self.usageSizesGB) { $0.toGBString() }
            picker("Transfer max", selection: $transferMaxGB, options: Self.dataSizesGB) { $0.toGBString() }
        } header: {
            header("Current plan")
        }
    }

    private var scenarioSection: some View {
        Section {
            picker("Scenario", selection: $scenario, options: Scenario.allCases) { $0.title }
        } header: {
            header("Scenario")
        }
    }

    private var recommendedPlanSection: some View {
        Section {
            picker("Plan", selection: recommendedTierSelection, options: recommendedTierOptions) { tierName($0) }
            picker("Billing cycle", selection: $cycle, options: Self.cycles) { $0.label }
            picker("Currency", selection: $currency, options: Self.currencies) { $0 }
            infoRow("Storage", recommendedTemplate.storageGB.toGBString())
            infoRow("Transfer", recommendedTemplate.transferGB.toGBString())
            infoRow("Price", formatted(recommendedTemplate.price(for: cycle)))
        } header: {
            header("Recommended plan")
        } footer: {
            Text("The recommended plan is a tier above the current plan; its storage, transfer and price are derived from the plan.")
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private var offerSection: some View {
        Section {
            picker("Offer", selection: $offerType, options: OfferType.allCases) { $0.label }
            if offerType != .none {
                picker("Duration", selection: durationSelection, options: currentDurations) { $0.title }
                if offerType != .freeTrial {
                    picker("Offer price", selection: $offerPrice, options: Self.prices) { formatted($0) }
                }
            }
        } header: {
            header("Introductory offer")
        } footer: {
            Text("Durations follow Apple's Standard Subscription Duration rules for a \(cycle.standardDurationTitle) plan.")
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private var startSection: some View {
        Section {
            Button("Start") { isPresentingDialog = true }
        }
    }

    // MARK: - Presented dialog

    @ViewBuilder private var dialog: some View {
        NavigationStack {
            switch scenario.kind {
            case let .storage(severity):
                StorageQuotaDialogView(
                    severity: severity,
                    useCase: qaUseCase,
                    onClose: { isPresentingDialog = false }
                )
            case let .transfer(severity):
                TransferQuotaDialogView(
                    severity: severity,
                    useCase: qaUseCase,
                    onClose: { isPresentingDialog = false }
                )
            }
        }
    }

    // MARK: - Use case assembly

    private var qaUseCase: QAQuotaDialogUseCase {
        QAQuotaDialogUseCase(accountDetails: accountDetails, plan: planEntity)
    }

    private var accountDetails: AccountDetailsEntity {
        AccountDetailsEntity(
            storageUsed: storageUsedGB.gigabytesToBytes(),
            versionsStorageUsed: 0,
            storageMax: storageMaxGB.gigabytesToBytes(),
            transferUsed: transferUsedGB.gigabytesToBytes(),
            transferMax: transferMaxGB.gigabytesToBytes(),
            proLevel: currentTier,
            proExpiration: 0,
            subscriptionStatus: .none,
            subscriptionRenewTime: 0,
            subscriptionMethod: nil,
            subscriptionMethodId: .none,
            subscriptionCycle: .none,
            numberUsageItems: 0,
            subscriptions: [],
            plans: [],
            storageUsedForHandle: { _ in 0 }
        )
    }

    private var planEntity: PlanEntity {
        let template = recommendedTemplate
        return PlanEntity(
            productIdentifier: "qa.recommendedPlan",
            type: template.tier,
            name: template.name,
            subscriptionCycle: cycle,
            storageLimit: template.storageGB,
            transferLimit: template.transferGB,
            appStorePrice: PlanPriceEntity(price: template.price(for: cycle), formattedPrice: "", currency: currency),
            introductoryOffer: introductoryOffer
        )
    }

    private var introductoryOffer: IntroductoryOfferEntity? {
        guard let paymentMode = offerType.paymentMode else { return nil }
        let duration = selectedDuration
        return IntroductoryOfferEntity(
            price: offerType == .freeTrial ? 0 : offerPrice,
            period: .init(unit: duration.unit, value: duration.value),
            periodCount: duration.periodCount,
            paymentMode: paymentMode
        )
    }

    // MARK: - Recommended plan must be a higher tier than the current plan

    /// Tiers ranked strictly above the current tier (the upgrade candidates).
    private var recommendedTierOptions: [AccountTypeEntity] {
        Self.catalog.filter { Self.rank(of: $0.tier) > Self.rank(of: currentTier) }.map(\.tier)
    }

    /// Stored selection clamped to the currently-valid options (they shrink as the current tier rises).
    private var selectedRecommendedTier: AccountTypeEntity {
        recommendedTierOptions.contains(recommendedTier) ? recommendedTier : (recommendedTierOptions.first ?? recommendedTier)
    }

    private var recommendedTierSelection: Binding<AccountTypeEntity> {
        Binding(get: { selectedRecommendedTier }, set: { recommendedTier = $0 })
    }

    /// The recommended plan's derived properties (name / storage / transfer / price) for its tier.
    private var recommendedTemplate: PlanTemplate { Self.template(for: selectedRecommendedTier) }

    private func tierName(_ tier: AccountTypeEntity) -> String { Self.template(for: tier).name }

    // MARK: - Offer duration (Apple Standard Subscription Duration rules)

    /// Valid durations for the current plan cycle + payment mode, per Apple's App Store Connect table.
    private var currentDurations: [OfferDuration] {
        switch offerType {
        case .none:
            []
        case .payAsYouGo:
            // Pay As You Go: monthly plan → 1…12 months (billed monthly); yearly plan → 1 year.
            switch cycle {
            case .yearly: [.payAsYouGoYear]
            case .monthly, .none: (1...12).map(OfferDuration.payAsYouGoMonths)
            }
        case .payUpFront:
            // Pay Up Front: 1, 2, 3, or 6 months, or 1 year — same for monthly and yearly plans.
            OfferDuration.payUpFront
        case .freeTrial:
            // Free Trial: 1, 2, 3, or 6 months, or 1 year (day/week not supported by MEGA).
            OfferDuration.freeTrial
        }
    }

    /// The stored selection clamped to the currently-valid options (options change with cycle / offer type).
    private var selectedDuration: OfferDuration {
        currentDurations.contains(offerDuration) ? offerDuration : (currentDurations.first ?? offerDuration)
    }

    private var durationSelection: Binding<OfferDuration> {
        Binding(get: { selectedDuration }, set: { offerDuration = $0 })
    }

    // MARK: - Helpers

    private func picker<Value: Hashable>(
        _ title: String,
        selection: Binding<Value>,
        options: [Value],
        label: @escaping (Value) -> String
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { option in
                Text(label(option)).tag(option)
            }
        }
        .pickerStyle(.menu)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private func header(_ text: String) -> some View {
        Text(text)
            .textCase(nil)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }

    private func formatted(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = .autoupdatingCurrent
        return formatter.string(for: value) ?? "\(value)"
    }
}

// MARK: - Selectable option types

private extension QuotaEventSimulatorView {
    /// The scenarios that map 1:1 to a `StorageQuotaSeverity` / `TransferQuotaSeverity`.
    enum Scenario: String, CaseIterable, Hashable {
        case storageAlmostFull = "Storage almost full"
        case storageFull = "Storage full"
        case transferLimitedDownload = "Transfer – limited download"
        case transferDownloadExceeded = "Transfer – download exceeded"
        case transferStreamingExceeded = "Transfer – streaming exceeded"

        var title: String { rawValue }

        enum Kind {
            case storage(StorageQuotaSeverity)
            case transfer(TransferQuotaSeverity)
        }

        var kind: Kind {
            switch self {
            case .storageAlmostFull: .storage(.almostFull)
            case .storageFull: .storage(.full)
            case .transferLimitedDownload: .transfer(.limitedDownload)
            case .transferDownloadExceeded: .transfer(.downloadExceeded)
            case .transferStreamingExceeded: .transfer(.streamingExceeded)
            }
        }
    }

    enum OfferType: String, CaseIterable, Hashable {
        case none = "None"
        case payUpFront = "Pay up front"
        case payAsYouGo = "Pay as you go"
        case freeTrial = "Free trial"

        var label: String { rawValue }

        var paymentMode: IntroductoryOfferEntity.PaymentMode? {
            switch self {
            case .none: nil
            case .payUpFront: .payUpFront
            case .payAsYouGo: .payAsYouGo
            case .freeTrial: .freeTrial
            }
        }
    }

    /// One selectable introductory-offer duration, encoding the concrete `(unit, value, periodCount)`
    /// that builds the `IntroductoryOfferEntity`. Values mirror Apple's Standard Subscription Duration table.
    struct OfferDuration: Hashable {
        let title: String
        let unit: BillingPeriodUnit
        let value: Int
        let periodCount: Int

        // Pay-up-front / free-trial: a single period covering the whole span (periodCount == 1).
        static let oneYear = OfferDuration(title: "1 Year", unit: .year, value: 1, periodCount: 1)

        static let payUpFront: [OfferDuration] = [
            OfferDuration(title: "1 Month", unit: .month, value: 1, periodCount: 1),
            OfferDuration(title: "2 Months", unit: .month, value: 2, periodCount: 1),
            OfferDuration(title: "3 Months", unit: .month, value: 3, periodCount: 1),
            OfferDuration(title: "6 Months", unit: .month, value: 6, periodCount: 1),
            .oneYear
        ]

        // MEGA supports only month/year periods, so day/week free trials aren't offered here.
        static let freeTrial: [OfferDuration] = payUpFront

        static let payAsYouGoYear = OfferDuration(title: "1 Year", unit: .year, value: 1, periodCount: 1)

        // Pay-as-you-go (monthly plan): N monthly charges — one 1-month period repeated `periodCount` times.
        static func payAsYouGoMonths(_ months: Int) -> OfferDuration {
            OfferDuration(
                title: months == 1 ? "1 Month" : "\(months) Months",
                unit: .month,
                value: 1,
                periodCount: months
            )
        }
    }

    /// A MEGA plan tier and its properties, for QA. `catalog` order defines the tier rank (cheapest first).
    struct PlanTemplate {
        let tier: AccountTypeEntity
        let name: String
        let storageGB: Int
        let transferGB: Int
        let monthlyPrice: Decimal
        let yearlyPrice: Decimal

        init(tier: AccountTypeEntity, name: String, storageGB: Int, transferGB: Int, monthly: String, yearly: String) {
            self.tier = tier
            self.name = name
            self.storageGB = storageGB
            self.transferGB = transferGB
            self.monthlyPrice = Decimal(string: monthly) ?? 0
            self.yearlyPrice = Decimal(string: yearly) ?? 0
        }

        func price(for cycle: SubscriptionCycleEntity) -> Decimal {
            cycle == .yearly ? yearlyPrice : monthlyPrice
        }
    }

    /// Ordered cheapest → most expensive; the index is the tier rank.
    static let catalog: [PlanTemplate] = [
        PlanTemplate(tier: .free, name: "Free", storageGB: 20, transferGB: 20, monthly: "0", yearly: "0"),
        PlanTemplate(tier: .lite, name: "Pro Lite", storageGB: 400, transferGB: 1024, monthly: "4.99", yearly: "49.99"),
        PlanTemplate(tier: .proI, name: "Pro I", storageGB: 2048, transferGB: 2048, monthly: "9.99", yearly: "99.99"),
        PlanTemplate(tier: .proII, name: "Pro II", storageGB: 8192, transferGB: 8192, monthly: "19.99", yearly: "199.99"),
        PlanTemplate(tier: .proIII, name: "Pro III", storageGB: 16384, transferGB: 16384, monthly: "29.99", yearly: "299.99")
    ]

    static func template(for tier: AccountTypeEntity) -> PlanTemplate {
        catalog.first { $0.tier == tier } ?? catalog[0]
    }

    static func rank(of tier: AccountTypeEntity) -> Int {
        catalog.firstIndex { $0.tier == tier } ?? 0
    }

    /// Current-plan tiers exclude the top tier, so a higher recommended tier always exists.
    static var currentTierOptions: [AccountTypeEntity] { catalog.dropLast().map(\.tier) }

    static let cycles: [SubscriptionCycleEntity] = [.monthly, .yearly]
    static let currencies = ["EUR", "USD", "GBP"]
    // Built from exact string decimals so floored per-month figures don't drift by a cent.
    static let prices: [Decimal] = ["4.99", "9.99", "19.99", "29.94", "40.01", "59.88", "60", "99.99", "119.88", "240"]
        .compactMap { Decimal(string: $0) }
    static let dataSizesGB = [20, 200, 400, 2048, 8192, 16384]
    static let usageSizesGB = [0, 1, 4, 10, 19, 100, 500, 1024, 2048]
}

private extension SubscriptionCycleEntity {
    var label: String {
        switch self {
        case .none: "None"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }

    /// The plan's standard subscription duration, per Apple's introductory-offer rules.
    var standardDurationTitle: String {
        switch self {
        case .yearly: "1 year"
        case .monthly, .none: "1 month"
        }
    }
}
#endif
