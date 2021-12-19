import SwiftUI

@available(iOS 14.0, *)
struct PhotoYearCard: View {
    @ObservedObject var viewModel: PhotoYearCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel) {
            Text(viewModel.title)
                .font(.title2.bold())
        }
    }
}
