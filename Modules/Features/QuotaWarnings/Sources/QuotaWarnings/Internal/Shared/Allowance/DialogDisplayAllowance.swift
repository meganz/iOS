/// A budget for presenting one specific dialog trigger.
///
/// A trigger's use case checks `isAvailable` before deciding to show its dialog,
/// and calls `consume()` only once the dialog was actually presented
///
/// Which budget a trigger spends is a composition choice made where the use case is built:
/// - two triggers share an allowance by being handed the same one.
/// - a trigger becomes uncapped by being handed `UnlimitedDialogAllowance`.
protocol DialogDisplayAllowance: Sendable {
    /// Whether the dialog may be presented right now.
    var isAvailable: Bool { get }

    /// Records that the dialog was presented.
    func consume()
}

/// An allowance that never runs out and records nothing, for triggers that are deliberately uncapped.
struct UnlimitedDialogAllowance: DialogDisplayAllowance {
    var isAvailable: Bool { true }

    func consume() {}
}
