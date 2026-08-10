import MEGADomain
import SwiftUI

/// Unavailable state of a file link. It still wraps the XIB the legacy screen shows; the revamped
/// empty state lands together with the file link content page.
struct FileLinkUnavailableView: UIViewRepresentable {
    let reason: LinkUnavailableReason

    func makeUIView(context: Context) -> UIView {
        guard let view = Bundle.main.loadNibNamed("UnavailableLinkView", owner: nil)?.first as? UnavailableLinkView else {
            return UIView()
        }

        switch reason {
        case .downETD:
            view.configureInvalidFileLinkByETD()
        case .userETDSuspension:
            view.configureInvalidFileLinkByUserETDSuspension()
        case .copyrightSuspension:
            view.configureInvalidFileLinkByUserCopyrightSuspension()
        case .generic:
            view.configureGenericInvalidFileLink()
        case .expired:
            view.configureInvalidFileLinkForExpired()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    FileLinkUnavailableView(reason: .generic)
}
