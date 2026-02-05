import FolderLink
import SwiftUI
import UIKit

struct FolderLinkMiniPlayerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: FolderLinkMiniPlayerViewModel
    
    func makeUIViewController(context: Context) -> UIViewController {
        FolderLinkMiniPlayerViewController(showing: $viewModel.showing, miniPlayerHeight: $viewModel.height)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
