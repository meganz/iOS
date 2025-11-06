import MEGADesignToken
import SwiftUI

struct PhotoCellVideoDurationViewModifier: ViewModifier {
    let viewModel: PhotoCellVideoDurationViewModel
    
    func body(content: Content) -> some View {
        content
            .overlay(videoOverlay, alignment: .bottomLeading)
    }
    
    private var videoOverlay: some View {
        Text(viewModel.duration)
            .font(.system(size: viewModel.fontSize))
            .foregroundColor(TokenColors.Text.primary.swiftUI)
            .padding(.init(top: 2, leading: 5, bottom: 2, trailing: 5))
            .background(TokenColors.Background.surface2.swiftUI)
            .cornerRadius(6.0)
            .offset(x: 5, y: viewModel.durationYOffset)
            .opacity(viewModel.shouldShowDuration ? 1 : 0)
    }
}

extension View {
    public func videoDuration(_ viewModel: PhotoCellVideoDurationViewModel) -> some View {
        modifier(PhotoCellVideoDurationViewModifier(viewModel: viewModel))
    }
}
