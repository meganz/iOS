
struct PhotoLibraryContentConfiguration {
    let selectLimit: Int?
    let scaleFactor: PhotoLibraryZoomState.ScaleFactor?
    
    init(selectLimit: Int? = nil, scaleFactor: PhotoLibraryZoomState.ScaleFactor? = nil) {
        self.selectLimit = selectLimit
        self.scaleFactor = scaleFactor
    }
}
