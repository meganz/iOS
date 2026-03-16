import MEGASwiftUI
import SwiftUI

@MainActor
final class HomeNavigation: ObservableObject {
    @Published var path = NavigationPath()
    @Published var snackBar: SnackBar?
    
    func append<Route>(_ route: Route) where Route: Hashable {
        path.append(route)
    }
    
    func removeLast() {
        path.removeLast()
    }
    
    func showSnackBar(_ snackBar: SnackBar) {
        self.snackBar = snackBar
    }
}
