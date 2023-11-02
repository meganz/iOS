import SwiftUI

struct CameraUploadStatusButtonView: View {
    @ObservedObject var viewModel: CameraUploadStatusButtonViewModel
    @State private var rotationDegrees = 0.0
    
    var body: some View {
        Button {
            // Handle pressed in CC-5455
        } label: {
            ZStack(alignment: .center) {
                if let progress = viewModel.progress {
                    progressView(progress: progress)
                }
                
                Image(viewModel.baseImageResource)
                    .resizable()
                    .frame(width: 21.5,
                           height: 21.5)
                
                if let statusImageResource = viewModel.statusImageResource {
                    Group {
                        Circle()
                            .fill(Color(Colors.General.Gray.navigationBgColor.color))
                            .frame(width: 15.5,
                                   height: 15.5)
                        
                        if viewModel.shouldRotateStatusImage {
                            statusImage(resource: statusImageResource)
                                .rotationEffect(.degrees(rotationDegrees))
                                .onAppear {
                                    withAnimation(statusImageAnimation) {
                                        rotationDegrees = 360.0
                                    }
                                }
                        } else {
                            statusImage(resource: statusImageResource)
                        }
                    }
                    .offset(x: 8,
                            y: 8)
                }
            }
            .frame(width: 28,
                   height: 28)
        }
    }
    
    private func statusImage(resource: ImageResource) -> some View {
        Image(resource)
            .resizable()
            .frame(width: 12.5,
                   height: 12.5)
    }
    
    private var statusImageAnimation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    private func progressView(progress: Float) -> some View {
        Circle()
            .trim(from: 0.0, to: min(CGFloat(progress), 1.0))
            .stroke(viewModel.progressLineColor, lineWidth: 1.6)
            .rotationEffect(.degrees(-90))
            .animation(.linear, value: progress)
            .frame(width: 27.5,
                   height: 27.5)
    }
}

struct CameraUploadStatusButtonView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            CameraUploadStatusButtonView(
                viewModel: .init(status: .enable))
            .previewDisplayName("Enable")
            
            CameraUploadStatusButtonView(
                viewModel: .init(status: .sync))
            .previewDisplayName("Sync / Check Status")
            
            CameraUploadStatusButtonView(
                viewModel: .init(status: .uploading(progress: 0.20)))
            .previewDisplayName("Progress 20%")
            
            CameraUploadStatusButtonView(
                viewModel: .init(status: .uploading(progress: 0.45)))
            .previewDisplayName("Progress 45%")
            
            CameraUploadStatusButtonView(
                viewModel: .init(status: .uploading(progress: 0.65)))
            .previewDisplayName("Progress 65%")
            
            CameraUploadStatusButtonView(
                viewModel: .init(status: .completed))
            .previewDisplayName("Completed")
            
            CameraUploadStatusButtonView(
                viewModel: .init(status: .idle))
            .previewDisplayName("Idle")
            
            CameraUploadStatusButtonView(
                viewModel: .init(status: .warning))
            .previewDisplayName("Warning")
            
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
