import MEGASdk

extension MEGAError: LocalizedError {
    public var errorDescription: String? {
        "\(name)(\(type.rawValue))"
    }
}
