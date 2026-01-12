import MEGADomain
import SwiftUI

struct TimelineMediaTabContentView: View {
    @ObservedObject var viewModel: MediaTimelineTabContentViewModel
    
    var body: some View {
        NewTimelineView(viewModel: viewModel.timelineViewModel)
            .task {
                await viewModel.monitorCameraUploads()
            }
    }
}
