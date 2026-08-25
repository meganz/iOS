import MEGAAppPresentation
import SwiftUI

public struct PhotoLibraryContentConfiguration {
    public let selectLimit: Int?
    let scaleFactor: PhotoLibraryZoomState.ScaleFactor?
    /// Overrides whether the bottom year/month/day/all picker is shown. `nil` keeps the default,
    /// which is derived from the content mode.
    let showsViewModePicker: Bool?

    public init(
        selectLimit: Int? = nil,
        scaleFactor: PhotoLibraryZoomState.ScaleFactor? = nil,
        showsViewModePicker: Bool? = nil
    ) {
        self.selectLimit = selectLimit
        self.scaleFactor = scaleFactor
        self.showsViewModePicker = showsViewModePicker
    }
}
