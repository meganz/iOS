import Home
import SwiftUI

final class HomeViewHostingController: UIHostingController<HomeView>, AdsSlotDisplayable {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureAdsVisibility()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        configureAdsVisibility()
    }
}
