import SwiftUI

struct PhotoMonthCard: View {
    @StateObject var viewModel: PhotoMonthCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel) {
            Text(viewModel.attributedTitle)
        }
    }
}
