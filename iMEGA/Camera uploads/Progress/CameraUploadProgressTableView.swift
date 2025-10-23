import SwiftUI

struct CameraUploadProgressTableView: UIViewControllerRepresentable {
    let viewModel: CameraUploadProgressTableViewModel
    
    init(viewModel: CameraUploadProgressTableViewModel) {
        self.viewModel = viewModel
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        CameraUploadProgressTableViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
