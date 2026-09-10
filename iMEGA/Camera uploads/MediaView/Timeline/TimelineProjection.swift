import ContentLibraries
import Foundation
import MEGADomain

/// The library the grid renders — or the one about to be published — together with the sections that
/// describe it.
///
/// Hydration is planned and applied against a projection rather than against the view model's
/// `dateSections`, because the two disagree for as long as a reactive pass is assembling a new
/// snapshot: planning reads the layout, then the fetch suspends, and by the time the result is
/// spliced `dateSections` may describe something else. Passing the pair as one value is what makes
/// the two ends of a hydration read the same layout. See `NewTimelineViewModel.commitProjection(_:sections:)`.
struct TimelineProjection: Sendable {
    let library: PhotoLibrary
    let sections: [MediaDateSectionEntity]
    /// Flattened once: planning and splicing both index it, and flattening is O(total photos).
    let photos: [NodeEntity]

    init(library: PhotoLibrary, sections: [MediaDateSectionEntity]) {
        self.library = library
        self.sections = sections
        self.photos = library.allPhotos
    }
}
