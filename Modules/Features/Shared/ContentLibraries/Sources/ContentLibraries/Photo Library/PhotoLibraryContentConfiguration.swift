public struct PhotoLibraryContentConfiguration {
    public let selectLimit: Int?
    let scaleFactor: PhotoLibraryZoomState.ScaleFactor?
    
    public init(selectLimit: Int? = nil, scaleFactor: PhotoLibraryZoomState.ScaleFactor? = nil) {
        self.selectLimit = selectLimit
        self.scaleFactor = scaleFactor
    }
}
