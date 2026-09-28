import SwiftUI
import UIKit

public final class PDFViewerViewController: UIViewController {
    private let viewerViewController: UIHostingController<PDFViewerView>

    public init(dependency: PDFViewerView.Dependency) {
        viewerViewController = UIHostingController(rootView: PDFViewerView(dependency: dependency))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        attachViewerView()
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
