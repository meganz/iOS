import Foundation

enum ZoomType {
    case `in`
    case out
}

struct PhotoLibraryZoomState {
    private static let supportedScaleFactors = [1, 3, 5]
    
    static let defaultScaleFactor = 3

    var scaleFactor: Int = Self.defaultScaleFactor
    
    func canZoom(_ type: ZoomType) -> Bool {
        switch type {
        case .in:
            return scaleFactor != Self.supportedScaleFactors.first
        case .out:
            return scaleFactor != Self.supportedScaleFactors.last
        }
    }
    
    mutating func zoom(_ type: ZoomType) {
        guard canZoom(type) else {
            return
        }
        
        guard let scaleIndex = Self.supportedScaleFactors.firstIndex(of: scaleFactor) else {
            scaleFactor = Self.defaultScaleFactor // Uses default scale if the current scale doesn't match our supported scales
            return
        }
        
        switch type {
        case .in:
            let index = Self.supportedScaleFactors.index(before: scaleIndex)
            scaleFactor = Self.supportedScaleFactors[index]
        case .out:
            let index = Self.supportedScaleFactors.index(after: scaleIndex)
            scaleFactor = Self.supportedScaleFactors[index]
        }
    }
}
