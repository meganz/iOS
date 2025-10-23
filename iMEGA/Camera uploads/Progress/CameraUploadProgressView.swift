import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct CameraUploadProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CameraUploadProgressTableViewModel
    
    var body: some View {
        NavigationStack {
            CameraUploadProgressTableView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(Strings.Localizable.CameraUploads.Progress.Navigation.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: { XmarkCloseButton() }
                    }
                }
                .hideNavigationToolbarBackground()
        }
        .pageBackground()
    }
}
