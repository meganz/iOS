import Combine
import Foundation

@MainActor
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
            .sink { @Sendable [weak self] isEditing in
                Task { @MainActor in
                    self?.updateMode(isEditing: isEditing)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func updateMode(isEditing: Bool) {
        if isEditing {
            viewModel.mode = .selection
        } else {
            viewModel.mode = defaultMode()
        }
    }
    
    private func defaultMode() -> VideoCellViewModel.Mode {
        switch viewModel.viewContext {
        case .allVideos:
                .plain
        case .playlistContent(let type) where type == .user:
                .reorder
        default:
                .plain
        }
    }
}
