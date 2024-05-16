import Foundation

/// Errors related to discovering the System Generated nodes.
public enum SystemGeneratedFolderLocationErrorEntity: Error, Equatable {
    /// The node does not exist for the given defined location.
    case nodeDoesNotExist(location: SystemGeneratedFolderLocationEntity)
    /// The means to load node has not been provided for the given location.
    case nodeAccessHasNotBeenProvided(location: SystemGeneratedFolderLocationEntity)
}
