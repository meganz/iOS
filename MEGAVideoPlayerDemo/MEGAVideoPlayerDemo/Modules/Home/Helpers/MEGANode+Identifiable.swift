import MEGASdk

extension MEGANode: @retroactive Identifiable {
    public var id: UInt64 { handle }
}
