import FolderLink
import SwiftUI

struct FolderLinkUnavailableView: UIViewRepresentable {
    let reason: LinkUnavailableReason
    
    func makeUIView(context: Context) -> UIView {
        guard let view = Bundle.main.loadNibNamed("UnavailableLinkView", owner: nil)?.first as? UnavailableLinkView else {
            return UIView()
        }
        
        switch reason {
        case .downETD:
            view.configureInvalidFolderLinkByETD()
        case .userETDSuspension:
            view.configureInvalidFolderLinkByUserETDSuspension()
        case .copyrightSuspension:
            view.configureInvalidFolderLinkByUserCopyrightSuspension()
        case .generic:
            view.configureGenericInvalidFolderLink()
        case .expired:
            view.configureInvalidFolderLinkForExpired()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    FolderLinkUnavailableView(reason: .downETD)
}
