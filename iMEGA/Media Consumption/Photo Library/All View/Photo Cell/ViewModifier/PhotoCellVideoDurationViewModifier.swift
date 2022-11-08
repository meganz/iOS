import SwiftUI

@available(iOS 14.0, *)
struct PhotoCellVideoDurationViewModifier: ViewModifier {
    let isVideo: Bool
    let duration: String
    let scaleFactor: PhotoLibraryZoomState.ScaleFactor
    let videModel = PhotoCellVideoDurationViewModel()
    
    func body(content: Content) -> some View {
        content
            .overlay(videoOverlay, alignment: .bottomLeading)
    }
    
    @ViewBuilder private var videoOverlay: some View {
        if isVideo {
            Text(duration)
                .font(.system(size: videModel.fontSize(with: scaleFactor)))
                .foregroundColor(Color.white)
                .padding(.init(top: 2,leading: 5 ,bottom: 2,trailing: 5))
                .background(Color.black.opacity(0.3))
                .cornerRadius(6.0)
                .frame(height: 20, alignment: .bottomLeading)
                .offset(x: 5, y: -5)
        }
    }
}

@available(iOS 14.0, *)
extension View {
    func videoDuration(_ isVideo: Bool,
                       duration: String,
                       with scaleFactor: PhotoLibraryZoomState.ScaleFactor = PhotoLibraryZoomState.defaultScaleFactor) -> some View {
        modifier(PhotoCellVideoDurationViewModifier(isVideo: isVideo, duration: duration, scaleFactor: scaleFactor))
    }
}
