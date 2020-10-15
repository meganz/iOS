import Foundation

struct RegionListViewRouter: RegionListViewRouting {
    private weak var navigationController: UINavigationController?
    private let regionCodes: [SMSRegion]
    private let onRegionSelected: (SMSRegion) -> Void
    
    init(navigationController: UINavigationController?, regionCodes: [SMSRegion], onRegionSelected: @escaping (SMSRegion) -> Void) {
        self.navigationController = navigationController
        self.regionCodes = regionCodes
        self.onRegionSelected = onRegionSelected
    }
    
    func build() -> UIViewController {
        let vm = RegionListViewModel(router: self, regionCodes: regionCodes)
        let vc = RegionListViewController(viewModel: vm)
        return vc
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
 
    // MARK: - UI Actions
    func goToRegion(_ region: SMSRegion) {
        navigationController?.popViewController(animated: true)
        onRegionSelected(region)
    }
}
