import MEGADomain
import MEGAPresentation
import SwiftUI

protocol DeviceListRouting: Routing {
    func showDeviceBackups(_ device: DeviceEntity)
}

public final class DeviceListViewRouter: NSObject, DeviceListRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let deviceListAssets: DeviceListAssets
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    
    public init(
        navigationController: UINavigationController?,
        deviceCenterUseCase: any DeviceCenterUseCaseProtocol,
        deviceListAssets: DeviceListAssets
    ) {
        self.navigationController = navigationController
        self.deviceListAssets = deviceListAssets
        self.deviceCenterUseCase = deviceCenterUseCase
        
        super.init()
    }
    
    public func build() -> UIViewController {
        let deviceListViewModel = DeviceListViewModel(
            router: self,
            deviceCenterUseCase: deviceCenterUseCase,
            deviceListAssets: deviceListAssets
        )
        let deviceListView = DeviceListView(viewModel: deviceListViewModel)
        let hostingController = UIHostingController(rootView: deviceListView)
        baseViewController = hostingController
        baseViewController?.title = deviceListAssets.title

        return hostingController
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func showDeviceBackups(_ device: DeviceEntity) {}
}
