public protocol ViewedLinksErrorReporting: Sendable {
    /// Reports a Viewed Links store failure the module recovered from.
    func reportError(_ error: any Error)
}
