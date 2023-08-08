import MEGADomain
import MEGAPresentation
import SwiftUI

public protocol BackupListRouting: Routing {
}

public final class BackupListViewRouter: NSObject, BackupListRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let deviceName: String
    private let backups: [BackupEntity]
    private let backupListAssets: BackupListAssets
    private let emptyStateAssets: EmptyStateAssets
    private let searchAssets: SearchAssets
    private let backupStatuses: [BackupStatus]
    
    public init(
        deviceName: String,
        backups: [BackupEntity],
        navigationController: UINavigationController?,
        backupListAssets: BackupListAssets,
        emptyStateAssets: EmptyStateAssets,
        searchAssets: SearchAssets,
        backupStatuses: [BackupStatus]
    ) {
        self.deviceName = deviceName
        self.backups = backups
        self.navigationController = navigationController
        self.backupListAssets = backupListAssets
        self.emptyStateAssets = emptyStateAssets
        self.searchAssets = searchAssets
        self.backupStatuses = backupStatuses
    }
    
    public func build() -> UIViewController {
        let backupListViewModel = BackupListViewModel(
            router: self,
            backups: backups,
            backupListAssets: backupListAssets,
            emptyStateAssets: emptyStateAssets,
            searchAssets: searchAssets,
            backupStatuses: backupStatuses
        )
        let backupListView = BackupListView(viewModel: backupListViewModel)
        let hostingController = UIHostingController(rootView: backupListView)
        baseViewController = hostingController
        baseViewController?.title = deviceName

        return hostingController
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
