import SwiftUI
import UIKit

private struct DisableSearchBarToolbarIntegrationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(SearchBarToolbarIntegrationConfigurator())
        } else {
            content
        }
    }
}

@available(iOS 26.0, *)
private struct SearchBarToolbarIntegrationConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SearchBarToolbarIntegrationController {
        SearchBarToolbarIntegrationController()
    }

    func updateUIViewController(_ uiViewController: SearchBarToolbarIntegrationController, context: Context) {
        uiViewController.disableToolbarIntegration()
    }
}

@available(iOS 26.0, *)
private final class SearchBarToolbarIntegrationController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        disableToolbarIntegration()
    }

    // SwiftUI rebuilds the navigation item as the toolbar content changes, so this is re-applied on
    // every update rather than only once.
    func disableToolbarIntegration() {
        parent?.navigationItem.searchBarPlacementAllowsToolbarIntegration = false
    }
}

public extension View {
    /// Keeps a `searchable` search bar in the navigation bar instead of letting iOS 26 move it into
    /// the bottom toolbar, which is what it does by default on iPhone.
    ///
    /// SwiftUI has no equivalent of `UINavigationItem.searchBarPlacementAllowsToolbarIntegration`,
    /// so the navigation item has to be reached directly. No effect before iOS 26.
    func disableSearchBarToolbarIntegration() -> some View {
        modifier(DisableSearchBarToolbarIntegrationModifier())
    }
}
