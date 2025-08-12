import QuartzCore

@MainActor
public protocol PlayerLayerProtocol {
    var bounds: CGRect { get }
    var layer: CALayer { get }
}
