import MEGAAppPresentation
import SwiftUI

public struct PhotoLibraryContentConfiguration {
    public let selectLimit: Int?
    let scaleFactor: PhotoLibraryZoomState.ScaleFactor?
    public let globalHeaderLeftViewProvider: (() -> AnyView)?

    public init(
        selectLimit: Int? = nil,
        scaleFactor: PhotoLibraryZoomState.ScaleFactor? = nil,
        globalHeaderLeftViewProvider: (() -> AnyView)? = nil
    ) {
        self.selectLimit = selectLimit
        self.scaleFactor = scaleFactor
        self.globalHeaderLeftViewProvider = globalHeaderLeftViewProvider
    }
}
