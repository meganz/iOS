

extension SIMD2 where Scalar == Double {
    var point: CGPoint {
        return CGPoint(x: self.x, y: self.y)
    }
}
