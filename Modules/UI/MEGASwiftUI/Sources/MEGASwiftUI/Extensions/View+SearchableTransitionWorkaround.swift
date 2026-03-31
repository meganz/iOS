import SwiftUI
import UIKit

private struct SearchableTransitionWorkaroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(SearchableTransitionConfigurator())
        } else {
            content
        }
    }
}

private struct SearchableTransitionConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SearchableTransitionController {
        SearchableTransitionController()
    }

    func updateUIViewController(_ uiViewController: SearchableTransitionController, context: Context) {}
}

private final class SearchableTransitionController: UIViewController {
    private var cachedSearchController: UISearchController?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard !isMovingFromParent,
              let parent,
              let searchController = parent.navigationItem.searchController else {
            return
        }

        cachedSearchController = searchController
        parent.navigationItem.searchController = nil

        if let navigationController = parent.navigationController,
           !navigationController.navigationBar.isHidden {
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.setNavigationBarHidden(false, animated: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let cachedSearchController,
              let parent else {
            return
        }

        parent.navigationItem.searchController = cachedSearchController
        self.cachedSearchController = nil
    }
}

public extension View {
    func searchableTransitionWorkaround() -> some View {
        modifier(SearchableTransitionWorkaroundModifier())
    }
}
