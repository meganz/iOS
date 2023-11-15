import SwiftUI

struct PhotoDayCard: View {
    @StateObject var viewModel: PhotoDayCardViewModel
    
    var body: some View {
        PhotoCard(viewModel: viewModel, badgeTitle: viewModel.badgeTitle) {
            Text(viewModel.attributedTitle)
        }
    }
}
