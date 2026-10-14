import SwiftUI
import UIKit

public final class PDFViewerViewController: UIViewController {
    private let viewerViewController: UIHostingController<PDFViewerView>
    private let lifecycleTracking: PDFViewerLifecycleTracking

    public init(dependency: PDFViewerView.Dependency) {
        viewerViewController = UIHostingController(rootView: PDFViewerView(dependency: dependency))
        lifecycleTracking = PDFViewerLifecycleTracking(
            trackingUseCase: dependency.trackingUseCase,
            onViewerPresented: dependency.onViewerPresented
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // `PDFViewerView` sets `.statusBarHidden`, which only the hosting
    // controller answers.
    public override var childForStatusBarHidden: UIViewController? {
        viewerViewController
    }

    public override var childForStatusBarStyle: UIViewController? {
        viewerViewController
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        attachViewerView()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifecycleTracking.viewerDidAppear()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || isMovingFromParent || navigationController?.isBeingDismissed == true {
            lifecycleTracking.viewerDidClose()
        }
    }

    private func attachViewerView() {
        navigationController?.navigationBar.isHidden = true
        addChild(viewerViewController)
        let viewerView: UIView = viewerViewController.view
        view.addSubview(viewerView)
        viewerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewerView.topAnchor.constraint(equalTo: view.topAnchor),
            viewerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        viewerViewController.didMove(toParent: self)
    }
}
