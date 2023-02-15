import Foundation

public enum PhotoLibraryErrorEntity: Error {
    case mediaUploadNodeDoesNotExist
    case cameraUploadNodeDoesNotExist
    case nodeDoesNotExist
}
