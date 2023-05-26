import MEGADomain

public extension HandleEntity {
    static func random() -> HandleEntity {
        HandleEntity.random(in: HandleEntity.min...HandleEntity.max)
    }
}
