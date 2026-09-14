public protocol ViewedLinksErrorReporting: Sendable {
    /// Reports an unrecoverable Viewed Links store failure.
    func reportFatalError(_ error: any Error) -> Never
}
