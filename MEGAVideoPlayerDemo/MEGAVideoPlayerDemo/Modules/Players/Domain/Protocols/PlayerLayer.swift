import QuartzCore

@MainActor
protocol PlayerLayerProtocol {
    var bounds: CGRect { get }
    var layer: CALayer { get }
}
