/// This protocol used to enable objects to trigger a menu refresh
/// action handlers can then trigger this closure to rebuild the context menu if state has change
@MainActor
protocol RefreshMenuTriggering: AnyObject {
    var refreshMenu: (() -> Void)? { get set }
}
