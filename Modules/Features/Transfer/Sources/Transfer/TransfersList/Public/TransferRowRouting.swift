import MEGADomain

/// Display data for the per-row action sheet header (mirrors the node-info header used
/// elsewhere, e.g. Cloud Drive): the file-type icon is derived from `name`, with `name`
/// as the title and `detail` (the row subtitle, e.g. "↑ 7 MB · 10 Aug 2024 19:09" or
/// "↑ Failed") below it.
public struct TransferRowActionContext: Sendable {
    public let name: String
    public let detail: String
    public let canViewInFolder: Bool

    public init(name: String, detail: String, canViewInFolder: Bool) {
        self.name = name
        self.detail = detail
        self.canViewInFolder = canViewInFolder
    }
}

/// App-implemented navigation boundary for per-row actions on the Transfers list.
///
/// Every destination (Cloud Drive, Offline, the system share sheet, Get Link, the
/// file previewer) lives in the app target and can't be built from this package, so
/// the composition root injects a concrete router through
/// `TransfersListViewControllerFactory.make(nodeUseCase:rowRouter:)`
@MainActor
public protocol TransferRowRouting: Sendable {
    /// Presents the per-row action sheet for a terminal transfer, matching the action
    /// sheet used elsewhere (e.g. Cloud Drive). The action set is derived from the
    /// transfer's state: Completed offers View in folder (only when `canViewInFolder`),
    /// Open with, Share link and Clear; Failed/Cancelled offer Retry and Clear.
    /// - Parameter context: header display data and view-in-folder eligibility.
    /// - Parameter onClear: invoked when the user taps Clear, so the list owner can
    ///   remove the entry (clearing lives in the Transfer package, not the app router).
    func presentActions(for transfer: TransferEntity, context: TransferRowActionContext, onClear: @MainActor @escaping () -> Void)
    /// Completed only. Opens or previews the finished file (row-body tap).
    func openFile(for transfer: TransferEntity)
}
