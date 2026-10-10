import FileProvider

extension NSFileProviderDomain {
    /// One fixed domain whichever account is logged in, so Files only ever shows one MEGA location.
    static var mega: NSFileProviderDomain {
        NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier("mega"), displayName: "MEGA")
    }
}
