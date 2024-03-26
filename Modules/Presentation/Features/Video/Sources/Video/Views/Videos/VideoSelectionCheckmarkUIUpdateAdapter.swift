import Combine
import Foundation

final class VideoSelectionCheckmarkUIUpdateAdapter {
    private let selection: VideoSelection
    private let viewModel: VideoCellViewModel
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(selection: VideoSelection, viewModel: VideoCellViewModel) {
        self.selection = selection
        self.viewModel = viewModel
        
        listenToVideoSelected()
    }
    
    func onTappedCheckMark() {
        selection.onTappedCheckMark(for: viewModel.nodeEntity)
    }
    
    private func listenToVideoSelected() {
        selection.isVideoSelectedPublisher(for: viewModel.nodeEntity)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSelected, on: viewModel)
            .store(in: &subscriptions)
    }
}
