import Combine
import MEGAL10n

extension VideoSelection {
    
    public func videoPlaylistContentTitlePublisher() -> AnyPublisher<String, Never> {
        let editModePublisher = $editMode.map { $0.isEditing }
        let videosPublisher = $videos
        
        return Publishers.CombineLatest(editModePublisher, videosPublisher)
            .removeDuplicates(by: { $0 == $1 })
            .map { [weak self] isEditing, videos in
                guard let self else { return "" }
                return title(whenIsEditing: isEditing, videosCount: videos.count)
            }
            .eraseToAnyPublisher()
    }
    
    private func title(whenIsEditing isEditing: Bool, videosCount: Int) -> String {
        if isEditing {
            if videosCount == 0 {
                Strings.Localizable.selectTitle
            } else {
                Strings.Localizable.General.Format.itemsSelected(videosCount)
            }
        } else {
            ""
        }
    }
}
