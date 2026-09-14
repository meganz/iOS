/// External dependencies the app injects into the Viewed Links module.
public enum DependencyInjection {
    // MARK: - External Injection
    nonisolated(unsafe) public static var errorReporting: (any ViewedLinksErrorReporting)?
}
