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
              let searchController = parent.navigationItem.searchController,
              let navigationController = parent.navigationController,
              !navigationController.navigationBar.isHidden else {
            return
        }

        // Only apply the workaround for push transitions within the navigation stack.
        // Use transitionCoordinator.viewController(forKey:) to reliably detect a push.
        // So we skip — tab switches don't need this visual fix and running the
        // synchronous toggle in that context causes a main-thread hang
        // (os_unfair_lock contention in CALayerGetSuperlayer during _UIAfterCACommitBlock).
        guard let coordinator = navigationController.transitionCoordinator,
              coordinator.viewController(forKey: .from) === parent else {
            return
        }

        cachedSearchController = searchController
        parent.navigationItem.searchController = nil

        coordinator.animate(alongsideTransition: { _ in
            navigationController.setNavigationBarHidden(true, animated: false)
            navigationController.setNavigationBarHidden(false, animated: false)
        })
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
