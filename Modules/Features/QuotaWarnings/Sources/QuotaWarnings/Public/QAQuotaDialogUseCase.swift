// Not wrapped in `#if DEBUG` — the QA configuration builds packages as release, so a compile-time
// guard would strip these types while the QA app target still references them. Unreachable in
// production: the only entry point is the QA settings screen, gated app-side.
import Foundation
import MEGADomain

/// One scripted step in a QA state sequence — how the next `upgradeOption()` call resolves, after an optional delay.
public struct QAQuotaStep: Sendable, Hashable {
    public enum Result: String, CaseIterable, Sendable {
        /// Resolve against the configured account + catalog (the real recommendation logic).
        case success
        /// Force the no-upgrade branch, regardless of catalog.
        case noUpgrade
        /// Throw — drives the `.error` state.
        case error
        /// Never resolves — parks on the loading skeleton.
        case loading
    }

    public let result: Result
    /// Seconds to wait (showing the skeleton) before this step resolves.
    public let delay: TimeInterval

    public init(result: Result, delay: TimeInterval) {
        self.result = result
        self.delay = delay
    }
}

/// A `QuotaDialogUseCaseProtocol` backed by explicit, in-memory values, for the QA dialog simulator.
///
/// Terminal modes:
/// - **`plan:`** — renders against a fixed, hand-picked `PlanEntity` (pass `nil` for the "no upgrade" state).
///   Bypasses the recommendation logic; used to pixel-check a specific card.
/// - **`catalog:`** — runs the **real** `RecommendedUpgradePlanUseCase` over the given catalog + account, so QA
///   exercises the actual selection rules (next-tier, discount override, no-upgrade, …).
///
/// Sequence mode:
/// - **`sequence:`** — scripts successive calls (step 1 = the initial load, each subsequent = a `retry()`), so QA
///   can watch loading → error/success transitions and drive the retry button. `.success` resolves against
///   `catalog`. The cursor **clamps to the last step** once the sequence is exhausted.
public struct QAQuotaDialogUseCase: QuotaDialogUseCaseProtocol {
    private enum Source {
        case fixed(PlanEntity?)
        case recommend([PlanEntity])
    }

    private let account: AccountDetailsEntity
    private let source: Source
    private let cursor: SequenceCursor?

    /// Manual mode — render the given plan (or the no-upgrade state when `nil`).
    public init(accountDetails: AccountDetailsEntity, plan: PlanEntity?) {
        self.account = accountDetails
        self.source = .fixed(plan)
        self.cursor = nil
    }

    /// Logic mode — run `RecommendedUpgradePlanUseCase` over `catalog` and render whatever it picks.
    public init(accountDetails: AccountDetailsEntity, catalog: [PlanEntity]) {
        self.account = accountDetails
        self.source = .recommend(catalog)
        self.cursor = nil
    }

    /// Sequence mode — script successive `upgradeOption()` calls; `.success` steps resolve against `catalog`.
    public init(accountDetails: AccountDetailsEntity, catalog: [PlanEntity], sequence: [QAQuotaStep]) {
        self.account = accountDetails
        self.source = .recommend(catalog)
        self.cursor = SequenceCursor(steps: sequence)
    }

    var userEmail: String? { nil }

    func upgradeOption() async throws -> QuotaUpgradeOption {
        guard let cursor, let step = await cursor.next() else {
            return configuredOutcome()
        }

        if step.delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(step.delay * 1_000_000_000))
        }

        switch step.result {
        case .success:
            return configuredOutcome()
        case .noUpgrade:
            return .unavailable(accountDetails: account)
        case .error:
            throw QAQuotaSimulatedError.scripted
        case .loading:
            // Never resolves — stays on the skeleton until the dialog is dismissed (cancels the sleep).
            try await Task.sleep(nanoseconds: .max)
            return configuredOutcome()
        }
    }

    /// The terminal outcome for the configured account + source (used by `.success` and non-sequenced calls).
    private func configuredOutcome() -> QuotaUpgradeOption {
        switch source {
        case let .fixed(plan):
            if let plan {
                .available(accountDetails: account, recommendedPlan: RecommendedUpgradePlanEntity(plan: plan))
            } else {
                .unavailable(accountDetails: account)
            }
        case let .recommend(catalog):
            if let recommendedPlan = recommend(from: catalog) {
                .available(accountDetails: account, recommendedPlan: recommendedPlan)
            } else {
                .unavailable(accountDetails: account)
            }
        }
    }

    private func recommend(from catalog: [PlanEntity]) -> RecommendedUpgradePlanEntity? {
        RecommendedUpgradePlanUseCase(subscriptionPlanPriceUseCase: SubscriptionPlanPriceUseCase())
            .recommend(for: account, from: catalog)
    }
}

private enum QAQuotaSimulatedError: Error {
    case scripted
}

/// Advances through a fixed step sequence, one step per `upgradeOption()` call, clamping to the last step.
private actor SequenceCursor {
    private let steps: [QAQuotaStep]
    private var index = 0

    init(steps: [QAQuotaStep]) {
        self.steps = steps
    }

    func next() -> QAQuotaStep? {
        guard !steps.isEmpty else { return nil }
        let step = steps[min(index, steps.count - 1)]
        index += 1
        return step
    }
}
