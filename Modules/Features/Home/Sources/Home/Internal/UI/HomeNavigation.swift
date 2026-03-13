import SwiftUI

@MainActor
final class HomeNavigation: ObservableObject {
    @Published var path = NavigationPath()
    
    func append<Route>(_ route: Route) where Route: Hashable {
        path.append(route)
    }
}
