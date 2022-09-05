import MEGADomain

extension CameraPositionEntity {
    func toCameraPositionCode() -> Int {
        switch self {
        case .unspecified: return 0
        case .back: return 1
        case .front: return 2
        }
    }
}
