public enum OfflineErrorEntity: Error {
    /// The URL does not point at an item inside the offline directory, so removing it would delete
    /// something else in the app's container.
    case itemOutsideOfflineDirectory
}
