import Foundation
import MEGAPresentation
import MEGADomain

enum GetLinkInfoCellAction: ActionType {
    case onViewReady
}

final class GetLinkAlbumInfoCellViewModel: ViewModelType, GetLinkCellViewModelType {
    enum Command: CommandType, Equatable {
        case setThumbnail(path: String)
        case setPlaceholderThumbnail
        case setLabels(title: String, subtitle: String)
    }
    
    var invokeCommand: ((Command) -> Void)?
    let type: GetLinkCellType = .info
    
    private let album: AlbumEntity
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    
    init(album: AlbumEntity, thumbnailUseCase: any ThumbnailUseCaseProtocol) {
        self.album = album
        self.thumbnailUseCase = thumbnailUseCase
    }
    
    func dispatch(_ action: GetLinkInfoCellAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.setLabels(title: album.name,
                                      subtitle: Strings.Localizable.General.Format.Count.items(album.count)))
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let node = album.coverNode else {
            invokeCommand?(.setPlaceholderThumbnail)
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let thumbnail = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
                invokeCommand?(.setThumbnail(path: thumbnail.url.path))
            } catch {
                MEGALogError("Error loading album cover thumbnail: \(error.localizedDescription)")
                invokeCommand?(.setPlaceholderThumbnail)
            }
        }
    }
}
