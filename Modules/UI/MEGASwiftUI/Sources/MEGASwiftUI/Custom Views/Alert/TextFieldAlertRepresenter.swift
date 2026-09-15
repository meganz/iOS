import SwiftUI
import UIKit

private struct TextFieldAlertRepresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let alert: TextFieldAlertViewModel

    func makeUIViewController(context: Context) -> TextFieldAlertHostController {
        TextFieldAlertHostController()
    }
    
    final class Coordinator {
        var alertController: UIAlertController?
        init(_ controller: UIAlertController? = nil) {
            self.alertController = controller
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func updateUIViewController(_ uiViewController: TextFieldAlertHostController, context: Context) {
        guard isPresented else {
            uiViewController.cancelPendingAlert()
            return
        }
        guard context.coordinator.alertController == nil else {
            uiViewController.presentPendingAlertIfPossible()
            return
        }
        
        let alertController = UIAlertController(alert: alert)
        context.coordinator.alertController = alertController
        uiViewController.enqueue(alertController) { presented in
            context.coordinator.alertController = nil
            if presented {
                isPresented = false
            }
        }
    }
}

/// Presents the alert put up by `TextFieldAlertRepresenter`.
///
/// SwiftUI gives the representer a bare controller sitting in the background of the view the alert is
/// attached to, and the first attempt to present from it can land before UIKit is willing to take it: the
/// screen it belongs to may still be animating in, or may not have reached a window yet. UIKit turns such a
/// `present` away with a console warning and never calls the completion handler back, so the alert is held
/// until the controller reaches a point in its lifecycle where presenting is allowed, rather than being
/// fired off once and assumed done.
private final class TextFieldAlertHostController: UIViewController {
    private var pendingAlert: UIAlertController?
    private var completion: (@MainActor (Bool) -> Void)?
    private var hasAppeared = false

    /// - Parameters:
    ///   - alert: the alert to put on screen, now or as soon as this controller is able to present it.
    ///   - completion: called with `true` once the alert is on screen, or with `false` if the alert is
    ///   withdrawn before that happens. Either way the caller is told the alert is no longer this
    ///   controller's to present.
    func enqueue(_ alert: UIAlertController, completion: @MainActor @escaping (Bool) -> Void) {
        pendingAlert = alert
        self.completion = completion
        presentPendingAlertIfPossible()
    }

    /// Withdraws an alert that is still waiting and tells its caller, so a caller that keeps state per
    /// alert is not left holding one this controller will never present.
    func cancelPendingAlert() {
        guard pendingAlert != nil else { return }
        finish(presented: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
        // The controller is in the view hierarchy and whatever transition brought it there has finished --
        // the lifecycle point an attempt made during `updateUIViewController` was too early for.
        presentPendingAlertIfPossible()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Covered by a full screen modal, or the screen was left: either way another `viewDidAppear` is
        // owed, so an alert arriving now has something to wait for again.
        hasAppeared = false
    }

    /// Also the representer's way in: every view update is offered as a chance to present, because it is
    /// the only change notification available for a modal put up over this screen going away again.
    fileprivate func presentPendingAlertIfPossible() {
        guard let alert = pendingAlert else { return }

        guard canPresent else {
            waitForNextOpportunity()
            return
        }

        // Cleared before presenting so a re-entrant attempt -- `viewDidAppear` arriving while the alert
        // animates in -- finds nothing to do.
        pendingAlert = nil
        present(alert, animated: true) { [weak self] in
            self?.finish(presented: true)
        }
    }

    /// The alert stays pending through all of these; this only subscribes to whatever will bring the next
    /// attempt about.
    private func waitForNextOpportunity() {
        guard hasAppeared else { return }

        // On screen but animating -- a sheet coming up over it, say. There is no appearance callback left
        // to wait for, but the running transition names its own end.
        if let transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.presentPendingAlertIfPossible()
            }
            return
        }
    }

    /// Walks its own parent chain rather than the window's: a presented controller has no `parent`, so the
    /// walk stops at the modal this alert belongs to and ignores whatever else the app has on screen.
    private var canPresent: Bool {
        // `viewIfLoaded` rather than `view`: a controller whose view has not loaded is not in a window
        // either way, and asking through `view` would load it as a side effect of a read-only check.
        guard viewIfLoaded?.window != nil else { return false }
        var controller: UIViewController? = self
        while let current = controller {
            guard current.presentedViewController == nil,
                  current.transitionCoordinator == nil else {
                return false
            }
            controller = current.parent
        }
        return true
    }

    private func finish(presented: Bool) {
        pendingAlert = nil
        let completion = self.completion
        self.completion = nil
        completion?(presented)
    }
}

public extension View {
    func alert(isPresented: Binding<Bool>, _ alert: TextFieldAlertViewModel) -> some View {
        background(TextFieldAlertRepresenter(isPresented: isPresented, alert: alert))
    }
}
