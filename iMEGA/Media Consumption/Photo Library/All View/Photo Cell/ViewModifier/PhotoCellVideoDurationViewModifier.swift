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
            .foregroundColor(UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary.swiftUI : .whiteFFFFFF)
            .padding(.init(top: 2, leading: 5, bottom: 2, trailing: 5))
            .background(UIColor.isDesignTokenEnabled() ? TokenColors.Background.surface2.swiftUI : .black000000.opacity(0.3))
            .cornerRadius(6.0)
            .offset(x: 5, y: viewModel.durationYOffset)
            .opacity(viewModel.shouldShowDuration ? 1 : 0)
    }
}

extension View {
    func videoDuration(_ viewModel: PhotoCellVideoDurationViewModel) -> some View {
        modifier(PhotoCellVideoDurationViewModifier(viewModel: viewModel))
    }
}
