import SwiftUI

@available(iOS 14.0, *)
struct PhotoMonthCard: View {
    @ObservedObject var viewModel: PhotoMonthCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel) {
            if #available(iOS 15.0, *) {
                Text(viewModel.attributedTitle)
            } else {
                Text(viewModel.title)
                    .font(.title2.bold())
            }
        }
    }
}
