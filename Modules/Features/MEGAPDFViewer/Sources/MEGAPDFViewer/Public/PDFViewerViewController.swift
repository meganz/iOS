import SwiftUI
import UIKit

public final class PDFViewerViewController: UIHostingController<PDFViewerView> {
    public init(dependency: PDFViewerView.Dependency) {
        super.init(rootView: PDFViewerView(dependency: dependency))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
