import UIKit

struct RoundCornerShadowConfiguration: Equatable {

    struct Corner: Equatable {
        let corners: UIRectCorner
        let radius: CGFloat
    }

    struct Shadow: Equatable {
        let radius: CGFloat
        let opacity: Float
        let offset: CGSize
        let color: UIColor
    }

    var backgroundColor = UIColor.whiteFFFFFF

    let corner: Corner
    let shadow: Shadow
}

private typealias CALayerTransformer = (CALayer) -> CALayer

private let roundingCorner: (RoundCornerShadowConfiguration) -> (CAShapeLayer) -> (CAShapeLayer) = { config in
    let corner = config.corner
    return { layer in
        let cornerRadii = CGSize(width: corner.radius, height: corner.radius)
        let cornerPath = UIBezierPath(roundedRect: layer.bounds, byRoundingCorners: corner.corners, cornerRadii: cornerRadii).cgPath
        layer.path = cornerPath
        layer.fillColor = config.backgroundColor.cgColor
        return layer
    }
}

private let shadowingCorner: (RoundCornerShadowConfiguration) -> CALayerTransformer = { config in
    let shadow = config.shadow
    return { layer in
        layer.shadowOffset = shadow.offset
        layer.shadowOpacity = shadow.opacity
        layer.shadowRadius = shadow.radius
        layer.shadowColor = shadow.color.cgColor
        return layer
    }
}

private let shadowingTop: (RoundCornerShadowConfiguration) -> CALayerTransformer = { config in
    let cornerRadius = config.corner.radius
    let cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
    return { layer in
        let bounds = layer.bounds
        let shadowBounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width, height: cornerRadius))
        let cornerPath = UIBezierPath(roundedRect: shadowBounds, byRoundingCorners: [.topRight, .topLeft], cornerRadii: cornerRadii).cgPath
        layer.shadowPath = cornerPath
        return layer
    }
}

private let addShapeLayerReader = Reader<UIView, CAShapeLayer> { view in
    let shapeLayer = CAShapeLayer()
    shapeLayer.frame = view.bounds
    view.layer.addSublayer(shapeLayer)
    return shapeLayer
}

private let dropTopRoundCornerShadow = Reader<RoundCornerShadowConfiguration, Reader<UIView, CALayer>> { config in
    let roundingTop = addShapeLayerReader <|> roundingCorner(config) <|> shadowingTop(config) <|> shadowingCorner(config)
    return roundingTop
}

extension RoundCornerShadowConfiguration {

    func dropTopCornerShadowStyler() -> Reader<UIView, CALayer> {
        dropTopRoundCornerShadow.runReader(self)
    }
}
