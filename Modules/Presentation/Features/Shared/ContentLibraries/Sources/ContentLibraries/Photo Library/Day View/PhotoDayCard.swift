import SwiftUI

public struct PhotoDayCard: View {
    @StateObject private var viewModel: PhotoDayCardViewModel
    
    public init(viewModel: @autoclosure @escaping () -> PhotoDayCardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        PhotoCard(viewModel: viewModel, badgeTitle: viewModel.badgeTitle) {
            Text(viewModel.attributedTitle)
        }
    }
}
