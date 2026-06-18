/// Whether each Transfers tab currently has any rows. Drives tab-bar visibility and the
/// per-tab More menu. Derived from the inventory by `MonitorTransferTabPresenceUseCase`.
struct TransferTabPresence: Equatable, Sendable {
    let hasActive: Bool
    let hasCompleted: Bool
    let hasFailed: Bool

    static let none = TransferTabPresence(hasActive: false, hasCompleted: false, hasFailed: false)
}
