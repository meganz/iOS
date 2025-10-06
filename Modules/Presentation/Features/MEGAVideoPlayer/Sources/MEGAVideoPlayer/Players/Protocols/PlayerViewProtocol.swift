import QuartzCore

@MainActor
public protocol PlayerViewProtocol {
    var bounds: CGRect { get }
    var layer: CALayer { get }
}
