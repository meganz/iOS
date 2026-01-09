import Foundation

enum ZoomType {
    case `in`
    case out
}

public struct PhotoLibraryZoomState: Equatable, Sendable {
    public enum ScaleFactor: Int, CaseIterable, Equatable, Sendable {
        case one = 1
        case three = 3
        case five = 5
        case thirteen = 13
    }

    var isSingleColumn: Bool { scaleFactor == .one }

    private let supportedScaleFactors: [ScaleFactor]

    public static let defaultScaleFactor: ScaleFactor = .three

    var scaleFactor: ScaleFactor
    var maximumScaleFactor: ScaleFactor

    public init(
        scaleFactor: ScaleFactor = .three,
        maximumScaleFactor: ScaleFactor = .thirteen,
        supportedScaleFactors: [ScaleFactor] = ScaleFactor.allCases
    ) {
        self.scaleFactor = scaleFactor
        self.maximumScaleFactor = maximumScaleFactor
        self.supportedScaleFactors = supportedScaleFactors
    }
    
    func canZoom(_ type: ZoomType) -> Bool {
        switch type {
        case .in:
            return scaleFactor != supportedScaleFactors.first
        case .out:
            return scaleFactor != maximumScaleFactor && scaleFactor != supportedScaleFactors.last
        }
    }
    
    mutating func zoom(_ type: ZoomType) {
        guard canZoom(type) else {
            return
        }
        
        guard let scaleIndex = supportedScaleFactors.firstIndex(of: scaleFactor) else {
            scaleFactor = Self.defaultScaleFactor // Uses default scale if the current scale doesn't match our supported scales
            return
        }
        
        switch type {
        case .in:
            let index = supportedScaleFactors.index(before: scaleIndex)
            scaleFactor = supportedScaleFactors[index]
        case .out:
            let index = supportedScaleFactors.index(after: scaleIndex)
            scaleFactor = supportedScaleFactors[index]
        }
    }
}
