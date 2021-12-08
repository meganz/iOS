import SwiftUI

@available(iOS 14.0, *)
struct PhotoDayCard: View {
    @ObservedObject var viewModel: PhotoDayCardViewModel
    
    var body: some View {
        PhotoCard(coverPhotoURL: viewModel.coverPhotoURL, badgeTitle: viewModel.badgeTitle) {
            if #available(iOS 15.0, *) {
                Text(viewModel.attributedTitle)
            } else {
                Text(viewModel.title)
                    .font(.title2.bold())
            }
        }
    }
}
