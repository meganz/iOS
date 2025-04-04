import MEGASdk

extension MEGAError: @retroactive LocalizedError, @unchecked Sendable {
    public var errorDescription: String? {
        "\(name)(\(type.rawValue))"
    }
}
