public extension MobileOfferEntity {
    var isAdvertisable: Bool {
        flags & Self.advertisableFlag != 0
    }

    /// Bit 0 of the `flags` bitmask, a strict opt-in from the API: only when it is set may the campaign be
    /// advertised on the mobile promotion surfaces. It does not affect whether the discount itself applies.
    private static let advertisableFlag = 1
}
