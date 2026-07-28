import MEGAUIKit
import SwiftUI
import UIKit

extension View {
    /// Installs a UIKit `UISearchController` on the navigation item hosting this view, and takes it down
    /// again once `isActive` turns false. The caller owns the button that starts a search, so it also owns
    /// where that button sits among the navigation bar items.
    ///
    /// `searchable` cannot do this. Collapsing it behind a button means attaching it only while search is
    /// active, and SwiftUI detaches it synchronously when search is cancelled, which resets the scroll
    /// position of the content underneath and, on a modally presented screen, dismisses the screen along
    /// with the search bar. Owning the controller lets the teardown wait for `didDismissSearchController`,
    /// by which point UIKit has finished its dismissal transition.
    ///
    /// - Parameters:
    ///   - text: Receives the query as it is typed.
    ///   - isActive: Set it to true to start searching. It is set back to false when the search bar is
    ///     dismissed, whichever way that happens.
    func navigationBarSearchController(text: Binding<String>, isActive: Binding<Bool>) -> some View {
        background(
            NavigationBarSearchControllerConfigurator(
                isActive: isActive.wrappedValue,
                onTextChange: { text.wrappedValue = $0 },
                onDismiss: { isActive.wrappedValue = false }
            )
        )
    }
}

private struct NavigationBarSearchControllerConfigurator: UIViewControllerRepresentable {
    let isActive: Bool
    let onTextChange: (String) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> NavigationBarSearchController {
        NavigationBarSearchController()
    }

    func updateUIViewController(_ uiViewController: NavigationBarSearchController, context: Context) {
        uiViewController.onTextChange = onTextChange
        uiViewController.onDismiss = onDismiss
        uiViewController.setSearchActive(isActive)
    }

    /// The host is a navigation destination that outlives this view — folder link swaps its content for the
    /// media discovery one in place — so everything put on it has to be taken back off here.
    static func dismantleUIViewController(_ uiViewController: NavigationBarSearchController, coordinator: ()) {
        uiViewController.restoreHost()
    }
}

/// An empty view controller whose only job is to reach the navigation item of the view controller hosting
/// the SwiftUI content, which is the one a `UISearchController` has to be installed on.
private final class NavigationBarSearchController: UIViewController {
    var onTextChange: ((String) -> Void)?
    var onDismiss: (() -> Void)?

    private lazy var searchController = UISearchController.customSearchController(
        searchResultsUpdaterDelegate: self,
        searchBarDelegate: self,
        searchControllerDelegate: self
    )

    /// Set between asking the search bar to dismiss and the dismissal completing. It decides whether the
    /// search controller can be taken off the navigation item there and then, not whether the dismissal
    /// counts: a search bar dismissed for any other reason — a push, the screen going away — still leaves
    /// search behind, it just cannot be unwired in the middle of whatever transition dismissed it.
    private var isExitingSearch = false

    private var isPresentingSearchBar = false

    /// Held on to so that the host can still be restored once this controller has been detached from it,
    /// and read in preference to `parent` for the same reason.
    private weak var host: UIViewController?
    private var hostDefinedPresentationContext: Bool?
    private var hostHidSearchBarWhenScrolling: Bool?

    private var hostViewController: UIViewController? {
        parent ?? host
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        guard let parent else { return }

        host = parent
        if hostDefinedPresentationContext == nil {
            hostDefinedPresentationContext = parent.definesPresentationContext
        }
        // Keeps the search bar's presentation contained in the screen that owns it, rather than letting it
        // travel up to whatever presented that screen.
        parent.definesPresentationContext = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reconciles both ways: a search bar this screen still owns is put back after a pop, and one left
        // on the navigation item by a dismissal that happened mid-transition is cleared.
        if isPresentingSearchBar {
            installSearchBar()
        } else {
            removeSearchBar()
        }
    }

    func setSearchActive(_ isActive: Bool) {
        if isActive {
            presentSearchBar()
        } else {
            dismissSearchBar()
        }
    }

    private func presentSearchBar() {
        guard !isPresentingSearchBar else {
            // Nothing to present, but SwiftUI may have cleared the navigation item since the last update.
            installSearchBar()
            return
        }

        isExitingSearch = false
        isPresentingSearchBar = true
        installSearchBar()

        // SwiftUI applies its own navigation item changes for this update after this method returns, and
        // those drop the search controller that was just installed, so the install is asserted once more on
        // the next turn of the run loop. Which is also where the search bar has to be activated from: doing
        // it in the same turn as the install leaves it without a layout to animate out of, so it appears
        // with no transition and no keyboard.
        DispatchQueue.main.async { [weak self] in
            guard let self, isPresentingSearchBar else { return }
            installSearchBar()
            searchController.isActive = true
            searchController.searchBar.becomeFirstResponder()
        }
    }

    private func installSearchBar() {
        guard isPresentingSearchBar,
              let host = hostViewController,
              host.navigationItem.searchController !== searchController else {
            return
        }

        host.navigationItem.searchController = searchController
        if hostHidSearchBarWhenScrolling == nil {
            hostHidSearchBarWhenScrolling = host.navigationItem.hidesSearchBarWhenScrolling
        }
        host.navigationItem.hidesSearchBarWhenScrolling = false
        host.navigationController?.view.layoutIfNeeded()
    }

    private func removeSearchBar() {
        guard let host = hostViewController,
              host.navigationItem.searchController === searchController else {
            return
        }
        host.navigationItem.searchController = nil
    }

    /// Puts the host back the way it was found, for when this controller goes away but the host does not.
    func restoreHost() {
        removeSearchBar()

        if let hostHidSearchBarWhenScrolling {
            hostViewController?.navigationItem.hidesSearchBarWhenScrolling = hostHidSearchBarWhenScrolling
        }
        if let hostDefinedPresentationContext {
            hostViewController?.definesPresentationContext = hostDefinedPresentationContext
        }
    }

    private func dismissSearchBar() {
        guard isPresentingSearchBar else { return }

        // Only ask for the dismissal here. Removing the controller from the navigation item while UIKit
        // still has the dismissal in flight is what takes the surrounding screen down with it, so that
        // waits for didDismissSearchController.
        isExitingSearch = true
        isPresentingSearchBar = false
        searchController.isActive = false
    }
}

// MARK: - UISearchResultsUpdating

extension NavigationBarSearchController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        onTextChange?(searchController.searchBar.text ?? "")
    }
}

// MARK: - UISearchBarDelegate

extension NavigationBarSearchController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isExitingSearch = true
    }
}

// MARK: - UISearchControllerDelegate

extension NavigationBarSearchController: UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        isPresentingSearchBar = false

        // Whatever dismissed the search bar, search is over, so the state this reports upwards is synced on
        // every path. Only the unwiring is conditional: a dismissal this screen did not ask for came from a
        // transition that is still running, and mutating the navigation item under it is what leaves UIKit
        // animating against a layer that is already gone. That one is cleared in viewWillAppear instead.
        if isExitingSearch {
            removeSearchBar()
        }
        isExitingSearch = false
        onDismiss?()
    }
}
