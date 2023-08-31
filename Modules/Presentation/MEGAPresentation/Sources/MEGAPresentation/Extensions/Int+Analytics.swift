import MEGAAnalyticsiOS

public extension Int {
    /// converts Integer to KotlinInt
    func toKotlinInt() -> KotlinInt {
        KotlinInt(integerLiteral: self)
    }
}
