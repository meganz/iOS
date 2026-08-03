import Combine
import Foundation
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGASwift
import QuotaWarnings
import SwiftUI

#if DEBUG || QA_CONFIG
/// QA-only screen for previewing the storage / transfer quota dialogs with fully configurable inputs.
///
/// Configure the **current plan** (tier + billing cycle + storage/transfer usage), pick a **scenario**, and
/// edit the **Plan list** (the purchasable catalog — each plan's level, cycle, price, discount, currency and
/// limits). The real `RecommendedUpgradePlanUseCase` runs the current plan against that catalog; the
/// **Recommendation** section shows what it picks (incl. price), and **Start** presents the real dialog with
/// the same result.
@MainActor
struct QuotaEventSimulatorView: View {
    // MARK: - Current plan
    @State private var currentTier: AccountTypeEntity = .free
    @State private var currentCycle: SubscriptionCycleEntity = .yearly
    @State private var storageUsedGB: Int = 19
    @State private var storageMaxGB: Int = 20
    @State private var transferUsedGB: Int = 4
    @State private var transferMaxGB: Int = 20

    // MARK: - Scenario
    @State private var scenario: Scenario = .storageAlmostFull

    // MARK: - Purchase simulation (one-tap Upgrade) — scripts the outcome the mock purchaser emits.
    @State private var purchaseScenario: MockPlanPurchasing.Scenario = .success

    // MARK: - Editable catalog (current-plan lookup + recommendation run against this)
    @State private var planList: [PlanConfig] = PlanConfig.defaultCatalog

    // MARK: - State sequence (scripts loading → error/success transitions + the retry button)
    @State private var useSequence = false
    @State private var steps: [StepConfig] = StepConfig.defaultSequence

    @State private var isPresentingDialog = false

    // MARK: - Display limit (the real once-a-day-per-trigger cap on the storage almost-full dialog)
    /// A capped trigger, identified by the label shown in the Display limit section.
    private struct CappedTrigger: Identifiable {
        let id: String
        let useCase: StorageAlmostFullDialogUseCase
    }

    private static let cappedTriggers: [CappedTrigger] = [
        CappedTrigger(id: "On app open", useCase: .onAppOpen),
        CappedTrigger(id: "After a successful upload", useCase: .afterSuccessfulUpload)
    ]

    // MARK: - Real SDK storage event (goes through AppDelegate onEvent:, unlike Start)
    @State private var eventScenario: DebugQuotaEventSimulator.StorageScenario = .almostFull
    @State private var eventSendCount = 1
    @State private var eventInterval: TimeInterval = 0

    @State private var allowanceStates: [String: QADailyAllowanceState] = [:]
    /// What each trigger's date picker shows — seeded from the stored date, or now when there is none.
    @State private var lastShownDateEdits: [String: Date] = [:]
    @State private var isPresentingLimitResetAlert = false

    var body: some View {
        List {
            currentPlanSection
            scenarioSection
            purchaseSection
            sequenceSection
            planListSection
            recommendationSection
            startSection
            storageEventSection
            displayLimitSection
        }
        .listStyle(.grouped)
        .navigationTitle("Quota dialog simulator")
        .sheet(isPresented: $isPresentingDialog) { dialog }
        .onAppear(perform: refreshDisplayLimitStatus)
        .alert("Daily limit reset", isPresented: $isPresentingLimitResetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Today's counts are cleared. The storage almost-full dialog can show once again "
                 + "from each real trigger.")
        }
    }

    // MARK: - Sections

    private var currentPlanSection: some View {
        Section {
            NavigationLink {
                CurrentPlanConfigView(
                    tierSelection: currentTierSelection,
                    tierOptions: currentTierOptions,
                    currentCycle: $currentCycle,
                    storageUsedGB: $storageUsedGB,
                    storageMaxGB: $storageMaxGB,
                    transferUsedGB: $transferUsedGB,
                    transferMaxGB: $transferMaxGB
                )
            } label: {
                summaryRow("Current plan", currentPlanSummary)
            }
        } footer: {
            Text("Storage \(storageUsedGB) / \(storageMaxGB) GB (used / limit) · "
                 + "Transfer \(transferUsedGB) / \(transferMaxGB) GB (used / limit)")
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private var scenarioSection: some View {
        Section {
            qaPicker("Scenario", selection: $scenario, options: Scenario.allCases) { $0.title }
        } header: {
            header("Scenario")
        }
    }

    private var purchaseSection: some View {
        Section {
            NavigationLink {
                PurchaseConfigView(scenario: $purchaseScenario)
            } label: {
                summaryRow("Purchase simulation", purchaseScenario.qaLabel)
            }
        }
    }

    private var sequenceSection: some View {
        Section {
            Toggle("Use step sequence", isOn: $useSequence)
            if useSequence {
                NavigationLink {
                    StepListView(steps: $steps)
                } label: {
                    HStack {
                        Text("Steps")
                        Spacer()
                        Text("\(steps.count) steps").foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    }
                }
            }
        } header: {
            header("State sequence")
        } footer: {
            Text("Scripts successive loads: step 1 = initial load, each next step = a Try Again tap. "
                 + "Delay shows the skeleton before the step resolves; result picks how it ends. Clamps to the last step.")
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private var planListSection: some View {
        Section {
            NavigationLink {
                PlanListView(plans: $planList)
            } label: {
                HStack {
                    Text("Plan list")
                    Spacer()
                    Text("\(planList.count) plans").foregroundStyle(TokenColors.Text.secondary.swiftUI)
                }
            }
        } header: {
            header("Catalog")
        }
    }

    private var recommendationSection: some View {
        Section {
            if let recommendation {
                infoRow("Recommends", recommendation.name)
                infoRow("Billing cycle", qaCycleLabel(recommendation.price))
                infoRow("Storage / Transfer", "\(recommendation.storage) · \(recommendation.transfer)")
                infoRow("Price", qaPriceSummary(recommendation.price))
            } else {
                infoRow("Recommends", "No upgrade available")
            }
        } header: {
            header("Recommendation (logic)")
        } footer: {
            Text("The real RecommendedUpgradePlanUseCase runs the current plan against the Plan list above.")
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private var startSection: some View {
        Section {
            Button("Start") { isPresentingDialog = true }
        }
    }

    /// Synthesizes a real SDK `EventStorage` and feeds it to `AppDelegate onEvent:`, so the whole
    /// production path runs — deferral while the tab bar is not yet root, the router's
    /// already-presenting guard, the daily allowance. Unlike **Start** above, which skips all of it.
    private var storageEventSection: some View {
        Section {
            qaPicker("Event", selection: $eventScenario, options: DebugQuotaEventSimulator.StorageScenario.allCases) {
                $0.title
            }
            qaPicker("Send", selection: $eventSendCount, options: QAConstants.eventSendCounts) {
                $0 == 1 ? "Once" : "\($0) times"
            }
            qaPicker("Interval", selection: $eventInterval, options: QAConstants.eventIntervals, label: qaDelayLabel)
            Button("Send") {
                DebugQuotaEventSimulator.shared.start(
                    .storage(eventScenario),
                    count: eventSendCount,
                    interval: eventInterval
                )
            }
            Button("Stop repeating", role: .destructive) {
                DebugQuotaEventSimulator.shared.stop()
            }
        } header: {
            header("Send storage event")
        } footer: {
            Text("Fires the event through the real AppDelegate path, so the daily allowance below applies. "
                 + "Interval waits before each send, including the first — use it to dismiss this page and "
                 + "watch the dialog land elsewhere; the run keeps going after you leave. At 0s the sends are "
                 + "back to back, so the already-presenting guard swallows all but the first.")
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    /// The real app caps the storage almost-full dialog at once a calendar day *per trigger*. Reports
    /// whether each allowance is spent, and clears them on demand.
    /// Note neither affects **Start** above, which presents the dialog directly rather than through
    /// the real trigger, so the cap never applies there.
    private var displayLimitSection: some View {
        Section {
            ForEach(Self.cappedTriggers) { trigger in
                DisclosureGroup {
                    infoRow("Shown count", shownCountText(for: trigger.id))
                    infoRow("Last shown", lastShownText(for: trigger.id))
                    DatePicker(
                        "Move last shown to",
                        selection: lastShownDateBinding(for: trigger),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    Button("Clear this trigger's count") {
                        trigger.useCase._resetDailyCount()
                        refreshDisplayLimitStatus()
                    }
                } label: {
                    infoRow(trigger.id, displayLimitStatus(for: trigger.id))
                }
            }
            Button("Reset storage almost-full daily limits") {
                StorageAlmostFullDialogUseCase._resetAllDailyCounts()
                refreshDisplayLimitStatus()
                isPresentingLimitResetAlert = true
            }
        } header: {
            header("Display limit")
        } footer: {
            Text("The storage almost-full dialog shows at most once a day (00:00–23:59) per trigger, and "
                 + "the two triggers have separate allowances. To test the same-day rule without waiting "
                 + "for midnight: trigger the dialog once, then move Last shown to another day — the count "
                 + "stays, but it no longer counts as today, so the dialog can show again. "
                 + "Trigger points without an allowance — over-quota error, album import — are "
                 + "unrestricted, as is Start above, which bypasses the router entirely.")
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private func displayLimitStatus(for triggerName: String) -> String {
        guard let state = allowanceStates[triggerName] else { return "—" }
        return state.isAvailable ? "Can still show today" : "Limit reached — won't show again today"
    }

    private func shownCountText(for triggerName: String) -> String {
        guard let state = allowanceStates[triggerName] else { return "—" }
        guard let dailyLimit = state.dailyLimit else { return "\(state.shownCount) (uncapped)" }
        return "\(state.shownCount) / \(dailyLimit)"
    }

    private func lastShownText(for triggerName: String) -> String {
        guard let lastShownDate = allowanceStates[triggerName]?.lastShownDate else { return "Never" }
        return lastShownDate.formatted(date: .abbreviated, time: .shortened)
    }

    /// Writes straight through to the stored preference, so the picker doubles as the editor — QA
    /// picks a date and the next real trigger already sees it.
    private func lastShownDateBinding(for trigger: CappedTrigger) -> Binding<Date> {
        Binding(
            get: { lastShownDateEdits[trigger.id] ?? Date() },
            set: { newDate in
                lastShownDateEdits[trigger.id] = newDate
                trigger.useCase._setLastShownDate(newDate)
                refreshDisplayLimitStatus()
            }
        )
    }

    /// Re-reads the production allowances. Called on appear and after every edit here — otherwise the
    /// counts only ever move via real triggers elsewhere in the app.
    private func refreshDisplayLimitStatus() {
        for trigger in Self.cappedTriggers {
            let state = trigger.useCase._allowanceState
            allowanceStates[trigger.id] = state
            // Keep whatever QA already picked when nothing is stored, so a cleared trigger does not
            // snap the picker back to now mid-edit.
            lastShownDateEdits[trigger.id] = state.lastShownDate ?? lastShownDateEdits[trigger.id] ?? Date()
        }
    }

    // MARK: - Presented dialog

    @ViewBuilder private var dialog: some View {
        NavigationStack {
            QuotaWarningDialogView(
                dependency: .init(quotaDialogUseCase: qaUseCase, planPurchaser: planPurchaser),
                kind: scenario.kind,
                onClose: { isPresentingDialog = false },
                onViewAllPlans: {}
            )
        }
    }

    // MARK: - Wiring

    private var planPurchaser: any PlanPurchasing {
        MockPlanPurchasing(scenario: purchaseScenario)
    }

    private var catalog: [PlanEntity] { planList.map { $0.toPlanEntity() } }

    private var qaUseCase: QAQuotaDialogUseCase {
        guard useSequence, !steps.isEmpty else {
            return QAQuotaDialogUseCase(accountDetails: accountDetails, catalog: catalog)
        }
        return QAQuotaDialogUseCase(
            accountDetails: accountDetails,
            catalog: catalog,
            sequence: steps.map { QAQuotaStep(result: $0.result, delay: $0.delay) }
        )
    }

    private var recommendation: RecommendedUpgradePlanEntity? {
        RecommendedUpgradePlanUseCase(subscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCase())
            .recommend(for: accountDetails, from: catalog)
    }

    private var accountDetails: AccountDetailsEntity {
        AccountDetailsEntity(
            storageUsed: storageUsedGB.gigabytesToBytes(),
            versionsStorageUsed: 0,
            storageMax: storageMaxGB.gigabytesToBytes(),
            transferUsed: transferUsedGB.gigabytesToBytes(),
            transferMax: transferMaxGB.gigabytesToBytes(),
            proLevel: selectedCurrentTier,
            proExpiration: 0,
            subscriptionStatus: .none,
            subscriptionRenewTime: 0,
            subscriptionMethod: nil,
            subscriptionMethodId: .none,
            subscriptionCycle: currentCycle,
            numberUsageItems: 0,
            subscriptions: [],
            plans: [],
            storageUsedForHandle: { _ in 0 }
        )
    }

    // MARK: - Current tier options (Free + whatever tiers the catalog defines)

    private var currentTierOptions: [AccountTypeEntity] {
        var tiers: [AccountTypeEntity] = [.free]
        for config in planList where !tiers.contains(config.tier) {
            tiers.append(config.tier)
        }
        return tiers
    }

    private var selectedCurrentTier: AccountTypeEntity {
        currentTierOptions.contains(currentTier) ? currentTier : (currentTierOptions.first ?? currentTier)
    }

    private var currentTierSelection: Binding<AccountTypeEntity> {
        Binding(get: { selectedCurrentTier }, set: {
            currentTier = $0
            syncCurrentPlan()
        })
    }

    /// The storage / transfer allowance (limits) for the selected tier, read from its catalog entry. The
    /// allowance is the same in both billing cycles (cycle only affects price), so this matches on tier
    /// alone. Free has no catalog entry, so it falls back to the free allowance.
    private func limits(for tier: AccountTypeEntity) -> (storage: Int, transfer: Int) {
        guard tier != .free, let plan = planList.first(where: { $0.tier == tier }) else {
            return (QAConstants.freeAllowanceGB, QAConstants.freeAllowanceGB)
        }
        return (plan.storageGB, plan.transferGB)
    }

    /// When the current tier changes, set the storage / transfer limits to the tier's allowance and rescale
    /// usage to keep the same fill ratio, so the whole current plan — usage and limits — reflects the pick
    /// and the recommendation runs against the right allowance.
    private func syncCurrentPlan() {
        let (newStorageMax, newTransferMax) = limits(for: selectedCurrentTier)
        storageUsedGB = rescaledUsage(storageUsedGB, fromMax: storageMaxGB, toMax: newStorageMax)
        transferUsedGB = rescaledUsage(transferUsedGB, fromMax: transferMaxGB, toMax: newTransferMax)
        storageMaxGB = newStorageMax
        transferMaxGB = newTransferMax
    }

    /// Rescales `used` from the old max to the new max (preserving the fill ratio) and snaps to the nearest
    /// usage option that does not exceed the new max, so the picker always has a matching value.
    private func rescaledUsage(_ used: Int, fromMax: Int, toMax: Int) -> Int {
        let ratio = fromMax > 0 ? Double(used) / Double(fromMax) : 0
        let target = Double(toMax) * ratio
        let options = QAConstants.usageSizesGB.filter { $0 <= toMax }
        guard let nearest = options.min(by: { abs(Double($0) - target) < abs(Double($1) - target) }) else {
            return min(used, toMax)
        }
        return nearest
    }

    // MARK: - Summaries

    private var currentPlanSummary: String {
        "\(PlanConfig.name(for: selectedCurrentTier)) · \(currentCycle.label) · \(storageUsedGB)/\(storageMaxGB) GB"
    }

    // MARK: - Small view helpers

    /// A tappable row: bold title + secondary summary of what's configured behind it.
    private func summaryRow(_ title: String, _ summary: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(summary)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
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
}

// MARK: - Scenario

private extension QuotaEventSimulatorView {
    /// The scenarios that map 1:1 to a `StorageQuotaSeverity` / `TransferQuotaSeverity`.
    enum Scenario: String, CaseIterable, Hashable {
        case storageAlmostFull = "Storage almost full"
        case storageFull = "Storage full"
        case storageFullUploadAttempt = "Storage full – upload attempt"
        case transferLimitedDownload = "Transfer – limited download"
        case transferLimitedStreaming = "Transfer – limited streaming"
        case transferDownloadExceeded = "Transfer – download exceeded"
        case transferStreamingExceeded = "Transfer – streaming exceeded"

        var title: String { rawValue }

        var kind: QuotaWarningDialogView.Kind {
            switch self {
            case .storageAlmostFull: .storage(.almostFull)
            case .storageFull: .storage(.full(.storageState))
            case .storageFullUploadAttempt: .storage(.full(.uploadAttempt))
            case .transferLimitedDownload: .transfer(.limitedDownload)
            case .transferLimitedStreaming: .transfer(.limitedStreaming)
            case .transferDownloadExceeded: .transfer(.downloadExceeded)
            case .transferStreamingExceeded: .transfer(.streamingExceeded)
            }
        }
    }
}

// MARK: - Current plan config (pushed)

private struct CurrentPlanConfigView: View {
    let tierSelection: Binding<AccountTypeEntity>
    let tierOptions: [AccountTypeEntity]
    @Binding var currentCycle: SubscriptionCycleEntity
    @Binding var storageUsedGB: Int
    @Binding var storageMaxGB: Int
    @Binding var transferUsedGB: Int
    @Binding var transferMaxGB: Int

    var body: some View {
        Form {
            qaPicker("Plan", selection: tierSelection, options: tierOptions) { PlanConfig.name(for: $0) }
            qaPicker("Billing cycle", selection: $currentCycle, options: QAConstants.cycles) { $0.label }
            qaPicker("Storage usage", selection: $storageUsedGB, options: QAConstants.usageSizesGB) { $0.toGBString() }
            qaPicker("Storage max", selection: $storageMaxGB, options: QAConstants.dataSizesGB) { $0.toGBString() }
            qaPicker("Transfer usage", selection: $transferUsedGB, options: QAConstants.usageSizesGB) { $0.toGBString() }
            qaPicker("Transfer max", selection: $transferMaxGB, options: QAConstants.dataSizesGB) { $0.toGBString() }
        }
        .navigationTitle("Current plan")
    }
}

// MARK: - Purchase simulation config (pushed)

private struct PurchaseConfigView: View {
    @Binding var scenario: MockPlanPurchasing.Scenario

    var body: some View {
        Form {
            Section {
                qaPicker("Scenario", selection: $scenario, options: QAConstants.purchaseScenarios) { $0.qaLabel }
            } footer: {
                Text("Tapping Upgrade in the dialog scripts this outcome so you can check the UI: success dismisses; "
                     + "failed / cancelled show their result; cancellable shows the Yes/No alert then succeeds or "
                     + "fails; non-cancellable shows the can't-purchase alert.")
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
        }
        .navigationTitle("Purchase simulation")
    }
}

// MARK: - Plan list editor

private struct PlanListView: View {
    @Binding var plans: [PlanConfig]

    var body: some View {
        List {
            ForEach($plans) { $plan in
                NavigationLink {
                    PlanEditorView(plan: $plan)
                } label: {
                    PlanRowView(plan: plan)
                }
            }
            .onDelete { plans.remove(atOffsets: $0) }
        }
        .navigationTitle("Plan list")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    plans.append(PlanConfig())
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

private struct PlanRowView: View {
    let plan: PlanConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(PlanConfig.name(for: plan.tier)).font(.headline)
                Spacer()
                Text(plan.cycle.label).foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            HStack {
                Text(qaFormatted(plan.price, plan.currency))
                if plan.offer.type != .none {
                    Text("· \(plan.offer.summary)")
                }
                Spacer()
                Text("\(plan.storageGB.toGBString()) / \(plan.transferGB.toGBString())")
            }
            .font(.caption)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }
}

private struct PlanEditorView: View {
    @Binding var plan: PlanConfig

    var body: some View {
        Form {
            Section {
                qaPicker("Plan level", selection: $plan.tier, options: QAConstants.tiers) { PlanConfig.name(for: $0) }
                qaPicker("Billing cycle", selection: $plan.cycle, options: QAConstants.cycles) { $0.label }
                qaPicker("Currency", selection: $plan.currency, options: QAConstants.currencies) { $0 }
                qaPicker("Price", selection: $plan.price, options: QAConstants.prices) { qaFormatted($0, plan.currency) }
                qaPicker("Storage limit", selection: $plan.storageGB, options: QAConstants.dataSizesGB) { $0.toGBString() }
                qaPicker("Transfer limit", selection: $plan.transferGB, options: QAConstants.dataSizesGB) { $0.toGBString() }
            } header: {
                Text("Plan")
            }

            Section {
                qaPicker("Type", selection: $plan.offer.type, options: QAOfferType.allCases) { $0.label }
                if plan.offer.type != .none {
                    qaPicker("Duration (months)", selection: $plan.offer.durationMonths, options: QAConstants.offerMonths) { "\($0) mo" }
                    if plan.offer.type != .freeTrial {
                        qaPicker("Offer price", selection: $plan.offer.price, options: QAConstants.prices) { qaFormatted($0, plan.currency) }
                    }
                }
            } header: {
                Text("Discount")
            }
        }
        .navigationTitle(PlanConfig.name(for: plan.tier))
    }
}

// MARK: - State sequence editor

private struct StepListView: View {
    @Binding var steps: [StepConfig]

    var body: some View {
        List {
            ForEach($steps) { $step in
                NavigationLink {
                    StepEditorView(step: $step)
                } label: {
                    StepRowView(step: step, number: (steps.firstIndex(of: step) ?? 0) + 1)
                }
            }
            .onDelete { steps.remove(atOffsets: $0) }
            .onMove { steps.move(fromOffsets: $0, toOffset: $1) }
        }
        .navigationTitle("State sequence")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    steps.append(StepConfig())
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

private struct StepRowView: View {
    let step: StepConfig
    let number: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            VStack(alignment: .leading, spacing: 2) {
                Text(step.result.qaLabel)
                Text(step.delay > 0 ? "after \(qaDelayLabel(step.delay))" : "immediately")
                    .font(.caption)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            Spacer()
        }
    }
}

private struct StepEditorView: View {
    @Binding var step: StepConfig

    var body: some View {
        Form {
            qaPicker("Result", selection: $step.result, options: QAQuotaStep.Result.allCases) { $0.qaLabel }
            qaPicker("Delay", selection: $step.delay, options: QAConstants.stepDelays) { qaDelayLabel($0) }
        }
        .navigationTitle(step.result.qaLabel)
    }
}

// MARK: - Editable models

private struct StepConfig: Identifiable, Hashable {
    var id = UUID()
    var result: QAQuotaStep.Result = .success
    var delay: TimeInterval = 1

    /// Demonstrates the retry flow out of the box: load → error, then a Try Again that succeeds.
    static let defaultSequence: [StepConfig] = [
        StepConfig(result: .error, delay: 2),
        StepConfig(result: .success, delay: 1)
    ]
}

private struct PlanConfig: Identifiable, Hashable {
    var id = UUID()
    var tier: AccountTypeEntity = .proI
    var cycle: SubscriptionCycleEntity = .yearly
    var price: Decimal = 0
    var currency: String = "EUR"
    var storageGB: Int = 0
    var transferGB: Int = 0
    var offer = QAOffer()

    func toPlanEntity() -> PlanEntity {
        PlanEntity(
            productIdentifier: "qa.\(tier).\(cycle)",
            type: tier,
            name: Self.name(for: tier),
            subscriptionCycle: cycle,
            storageLimit: storageGB,
            transferLimit: transferGB,
            appStorePrice: PlanPriceEntity(price: price, formattedPrice: "", currency: currency),
            introductoryOffer: offer.toEntity()
        )
    }

    static func name(for tier: AccountTypeEntity) -> String {
        switch tier {
        case .free: "Free"
        case .lite: "Pro Lite"
        case .proI: "Pro I"
        case .proII: "Pro II"
        case .proIII: "Pro III"
        case .starter: "Starter"
        case .basic: "Basic"
        case .essential: "Essential"
        default: "\(tier)"
        }
    }

    /// Every non-free tier in both cycles, no discounts by default.
    static let defaultCatalog: [PlanConfig] = {
        let base: [(tier: AccountTypeEntity, storage: Int, transfer: Int, monthly: String, yearly: String)] = [
            (.lite, 400, 1024, "4.99", "49.99"),
            (.proI, 2048, 2048, "9.99", "99.99"),
            (.proII, 8192, 8192, "19.99", "199.99"),
            (.proIII, 16384, 16384, "29.99", "299.99")
        ]
        return base.flatMap { row in
            [SubscriptionCycleEntity.monthly, .yearly].map { cycle in
                PlanConfig(
                    tier: row.tier,
                    cycle: cycle,
                    price: Decimal(string: cycle == .yearly ? row.yearly : row.monthly) ?? 0,
                    currency: "EUR",
                    storageGB: row.storage,
                    transferGB: row.transfer
                )
            }
        }
    }()
}

private struct QAOffer: Hashable {
    var type: QAOfferType = .none
    var price: Decimal = 0
    var durationMonths: Int = 12

    func toEntity() -> SubscriptionOfferEntity? {
        guard let paymentMode = type.paymentMode else { return nil }
        return SubscriptionOfferEntity(
            price: type == .freeTrial ? 0 : price,
            period: .init(unit: .month, value: type == .payAsYouGo ? 1 : durationMonths),
            periodCount: type == .payAsYouGo ? durationMonths : 1,
            paymentMode: paymentMode
        )
    }

    var summary: String {
        switch type {
        case .none: "—"
        case .freeTrial: "Free · \(durationMonths) mo"
        case .payUpFront: "Upfront · \(durationMonths) mo"
        case .payAsYouGo: "PAYG · \(durationMonths) mo"
        }
    }
}

private enum QAOfferType: String, CaseIterable, Hashable {
    case none = "None"
    case payUpFront = "Pay up front"
    case payAsYouGo = "Pay as you go"
    case freeTrial = "Free trial"

    var label: String { rawValue }

    var paymentMode: SubscriptionOfferEntity.PaymentMode? {
        switch self {
        case .none: nil
        case .payUpFront: .payUpFront
        case .payAsYouGo: .payAsYouGo
        case .freeTrial: .freeTrial
        }
    }
}

private enum QAConstants {
    static let tiers: [AccountTypeEntity] = [.lite, .proI, .proII, .proIII]
    static let cycles: [SubscriptionCycleEntity] = [.monthly, .yearly]
    /// Purchase outcomes the simulator can script (every case except the `.idle` preview default).
    static let purchaseScenarios: [MockPlanPurchasing.Scenario] = MockPlanPurchasing.Scenario.allCases.filter { $0 != .idle }
    static let currencies = ["EUR", "USD", "GBP"]
    static let offerMonths = [1, 2, 3, 6, 12]
    static let dataSizesGB = [20, 200, 400, 1024, 2048, 8192, 16384]
    static let usageSizesGB = [0, 1, 4, 10, 19, 100, 500, 1024, 2048]
    static let stepDelays: [TimeInterval] = [0, 0.5, 1, 2, 3, 5]
    /// How many times the storage event simulator fires, and how long it waits before each send.
    static let eventSendCounts = [1, 2, 3, 5, 10]
    static let eventIntervals: [TimeInterval] = [0, 1, 3, 5, 10, 30]
    /// Allowance used for the current plan when Free is selected (no catalog entry to derive limits from).
    static let freeAllowanceGB = 20
    // Exact string decimals so floored per-month figures don't drift by a cent.
    static let prices: [Decimal] = [
        "0", "4.99", "9.99", "19.99", "24", "29.94", "29.99", "40.01", "48", "49.99",
        "59.88", "60", "96", "99.99", "119.88", "120", "199.99", "240", "299.99"
    ].compactMap { Decimal(string: $0) }
}

// MARK: - Shared helpers

private func qaPicker<Value: Hashable>(
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

private func qaDelayLabel(_ seconds: TimeInterval) -> String {
    seconds == seconds.rounded() ? "\(Int(seconds))s" : String(format: "%.1fs", seconds)
}

private extension QAQuotaStep.Result {
    var qaLabel: String {
        switch self {
        case .success: "Success"
        case .noUpgrade: "No upgrade"
        case .error: "Error"
        case .loading: "Loading (stuck)"
        }
    }
}

private func qaFormatted(_ value: Decimal, _ currency: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currency
    formatter.locale = .autoupdatingCurrent
    return formatter.string(for: value) ?? "\(value)"
}

private func qaCycleLabel(_ price: SubscriptionPlanPrice) -> String {
    switch price {
    case .monthly, .discountMonthly: "Monthly"
    case .yearly, .discountYearly: "Yearly"
    }
}

private func qaPriceSummary(_ price: SubscriptionPlanPrice) -> String {
    switch price {
    case let .monthly(model):
        "\(qaFormatted(model.price, model.currency))/mo"
    case let .yearly(model):
        "\(qaFormatted(model.price, model.currency))/yr"
    case let .discountMonthly(model):
        "\(qaFormatted(model.offer.schedule.pricePerMonth, model.monthly.currency))/mo (-\(model.offer.discountPercentage)%)"
    case let .discountYearly(model):
        "\(qaFormatted(model.offer.schedule.pricePerMonth, model.yearly.currency))/mo (-\(model.offer.discountPercentage)%)"
    }
}

private extension SubscriptionCycleEntity {
    var label: String {
        switch self {
        case .none: "None"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}

private extension MockPlanPurchasing.Scenario {
    var qaLabel: String {
        switch self {
        case .success: "Buy succeeds"
        case .failed: "Buy fails"
        case .cancelledByUser: "User cancels"
        case .cancellableThenSuccess: "Cancellable sub → then succeeds"
        case .cancellableThenFailed: "Cancellable sub → then fails"
        case .nonCancellable: "Non-cancellable sub"
        case .idle: "Idle"
        }
    }
}

// MARK: - Purchase simulation (mock)

/// A `PlanPurchasing` that scripts outcomes for the QA simulator so every purchase branch can be exercised
/// without real StoreKit or a real active subscription. It emits the same outcome sequence the real
/// `PlanPurchaser` would for each situation, and — like the real `MEGAPurchase` — drives `SVProgressHUD`
/// while the purchase is in flight, so the QA experience matches production.
@MainActor
final class MockPlanPurchasing: PlanPurchasing {
    enum Scenario: String, CaseIterable, Sendable {
        case success
        case failed
        case cancelledByUser
        case cancellableThenSuccess
        case cancellableThenFailed
        case nonCancellable
        /// Emits nothing on tap.
        case idle
    }

    private let scenario: Scenario
    private let subject = PassthroughSubject<PlanPurchaseOutcome, Never>()

    var outcomes: AnyPublisher<PlanPurchaseOutcome, Never> { subject.eraseToAnyPublisher() }

    init(scenario: Scenario = .idle) { self.scenario = scenario }

    func purchase(productIdentifier: String) async {
        switch scenario {
        case .success:
            await runPurchasing(then: .succeeded)
        case .failed:
            await runPurchasing(then: .failed)
        case .cancelledByUser:
            await runPurchasing(then: .cancelled)
        case .nonCancellable:
            // Blocked before any purchase starts — no `.purchasing`, just the inform outcome.
            subject.send(.cannotPurchaseWithActiveSubscription)
        case .cancellableThenSuccess, .cancellableThenFailed:
            let afterConfirm: PlanPurchaseOutcome = scenario == .cancellableThenSuccess ? .succeeded : .failed
            subject.send(.requiresCancellationConfirmation(confirmCancelAndBuy: { [weak self] in
                await self?.runPurchasing(then: afterConfirm)
            }))
        case .idle:
            break
        }
    }

    /// Emits `.purchasing`, shows the loading HUD like the real `MEGAPurchase`, waits so the busy state is
    /// visible, then dismisses the HUD and emits the terminal outcome.
    private func runPurchasing(then terminal: PlanPurchaseOutcome) async {
        subject.send(.purchasing)
        SVProgressHUD.show()
        try? await Task.sleep(nanoseconds: 600_000_000)
        await SVProgressHUD.dismiss()
        subject.send(terminal)
    }
}
#endif
