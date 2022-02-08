import Foundation

enum ZoomAction {
    case zoomIn
    case zoomOut
}

enum ZoomLevel: Hashable {
    case `default`(Int)
    case oneColumn(Int)
    case fiveColumns(Int)
    
    var value: Int {
        switch self {
        case .default(let value):
            return value
        case .oneColumn(let value):
            return value
        case .fiveColumns(let value):
            return value
        }
    }
}

struct PhotoLibraryZoom: Hashable {
    var currentZoomLevel: ZoomLevel
    var action: ZoomAction?
}

struct ZoomLevelManagement {
    private let statesTable: [PhotoLibraryZoom: ZoomLevel] = [PhotoLibraryZoom(currentZoomLevel: .default(PhotoLibraryConstants.defaultColumnsNumber), action: .zoomIn): .oneColumn(PhotoLibraryConstants.oneColumnNumber),
                                                              PhotoLibraryZoom(currentZoomLevel: .default(PhotoLibraryConstants.defaultColumnsNumber), action: .zoomOut): .fiveColumns(PhotoLibraryConstants.fiveColumnsNumber),
                                                              
                                                              PhotoLibraryZoom(currentZoomLevel: .oneColumn(PhotoLibraryConstants.oneColumnNumber), action: .zoomIn): .oneColumn(PhotoLibraryConstants.oneColumnNumber),
                                                              PhotoLibraryZoom(currentZoomLevel: .oneColumn(PhotoLibraryConstants.oneColumnNumber), action: .zoomOut): .default(PhotoLibraryConstants.defaultColumnsNumber),
                                                              
                                                              PhotoLibraryZoom(currentZoomLevel: .fiveColumns(PhotoLibraryConstants.fiveColumnsNumber), action: .zoomOut): .fiveColumns(PhotoLibraryConstants.fiveColumnsNumber),
                                                              PhotoLibraryZoom(currentZoomLevel: .fiveColumns(PhotoLibraryConstants.fiveColumnsNumber), action: .zoomIn): .default(PhotoLibraryConstants.defaultColumnsNumber)
    ]
    
    func next(currentState level: ZoomLevel, action: ZoomAction) -> ZoomLevel {
        let zoomInfo = PhotoLibraryZoom(currentZoomLevel: level, action: action)
        return statesTable[zoomInfo] ?? .default(PhotoLibraryConstants.defaultColumnsNumber)
    }
}
