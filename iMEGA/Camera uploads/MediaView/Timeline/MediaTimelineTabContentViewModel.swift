import Combine
import SwiftUI

@MainActor
final class MediaTimelineTabContentViewModel: ObservableObject, MediaTabContentViewModel {
    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)?
    let editModeToggleRequested = PassthroughSubject<Void, Never>()
   
    let timelineViewModel: NewTimelineViewModel
    
    init(timelineViewModel: NewTimelineViewModel) {
        self.timelineViewModel = timelineViewModel
    }
}
