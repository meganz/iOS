import Foundation
import UIKit

@MainActor
protocol PDFViewerActivityPresenting {
    func presentLink(_ link: String, from presenter: UIViewController, sender: Any)

    func present(
        fileURL: URL?,
        from presenter: UIViewController?,
        anchor: UIView?,
        barItem: UIBarButtonItem?,
        onPresented: (@MainActor () -> Void)?
    )
}

@MainActor final class PDFViewerActivityPresenter: PDFViewerActivityPresenting {
    func presentLink(_ link: String, from presenter: UIViewController, sender: Any) {
        present(
            activityItems: [link], from: presenter, anchor: sender as? UIView,
            barItem: sender as? UIBarButtonItem, onPresented: nil
        )
    }

    func present(
        fileURL: URL?,
        from presenter: UIViewController?,
        anchor: UIView?,
        barItem: UIBarButtonItem?,
        onPresented: (@MainActor () -> Void)?
    ) {
        guard let fileURL else {
            onPresented?()
            return
        }
        present(
            activityItems: [fileURL], from: presenter, anchor: anchor,
            barItem: barItem, onPresented: onPresented
        )
    }

    private func present(
        activityItems: [Any],
        from presenter: UIViewController?,
        anchor: UIView?,
        barItem: UIBarButtonItem?,
        onPresented: (@MainActor () -> Void)?
    ) {
        guard let presenter, presenter.presentedViewController == nil else {
            onPresented?()
            return
        }
        let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            if #available(iOS 26.0, *), let barItem {
                popover.barButtonItem = barItem
            } else if let anchor, anchor.window != nil, !anchor.bounds.isEmpty {
                popover.sourceView = anchor
                popover.sourceRect = anchor.bounds
            } else {
                popover.sourceView = presenter.view
                popover.sourceRect = CGRect(
                    x: presenter.view.bounds.midX,
                    y: presenter.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
        }
        presenter.present(activity, animated: true, completion: onPresented)
    }
}
