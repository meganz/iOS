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
        listenToCellState()
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
    
    private func listenToCellState() {
        selection.$editMode.map(\.isEditing)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditing in
                guard let self else { return }
                if isEditing {
                    viewModel.mode = .selection
                } else {
                    viewModel.mode = defaultMode()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func defaultMode() -> VideoCellViewModel.Mode {
        switch viewModel.viewContext {
        case .allVideos:
                .plain
        case .playlistContent:
                .reorder
        }
    }
}
