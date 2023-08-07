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
    private let backupStatuses: [BackupStatus]
    
    public init(
        deviceName: String,
        backups: [BackupEntity],
        navigationController: UINavigationController?,
        backupListAssets: BackupListAssets,
        backupStatuses: [BackupStatus]
    ) {
        self.deviceName = deviceName
        self.backups = backups
        self.navigationController = navigationController
        self.backupListAssets = backupListAssets
        self.backupStatuses = backupStatuses
    }
    
    public func build() -> UIViewController {
        let backupListViewModel = BackupListViewModel(
            router: self,
            backups: backups,
            backupListAssets: backupListAssets,
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
