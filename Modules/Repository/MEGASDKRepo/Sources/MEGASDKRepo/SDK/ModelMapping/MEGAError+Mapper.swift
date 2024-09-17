import MEGASdk

extension MEGAError: @retroactive LocalizedError {
    public var errorDescription: String? {
        "\(name)(\(type.rawValue))"
    }
}
