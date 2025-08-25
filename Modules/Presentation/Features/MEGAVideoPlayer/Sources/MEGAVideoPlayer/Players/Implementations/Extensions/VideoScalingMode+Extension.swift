import AVFoundation

extension VideoScalingMode {
    func toAVLayerVideoGravity() -> AVLayerVideoGravity {
        switch self {
        case .fit: .resizeAspect
        case .fill: .resizeAspectFill
        }
    }
}
