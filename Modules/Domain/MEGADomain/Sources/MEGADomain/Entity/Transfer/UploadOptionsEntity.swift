import Foundation

/// Upload trigger tags representing the source of an upload action.
public enum PitagTriggerEntity: Sendable {
    /// Not applicable or default trigger
    case notApplicable
    /// Upload initiated from a file picker
    case picker
    /// Upload initiated from drag and drop
    case dragAndDrop
    /// Upload initiated from camera
    case camera
    /// Upload initiated from a scanner
    case scanner
    /// Upload initiated by sync algorithm
    case syncAlgorithm
    /// Upload initiated from share from app
    case shareFromApp
    /// Upload initiated from camera capture
    case cameraCapture
    /// Upload initiated from explorer extension
    case explorerExtension
    /// Upload initiated from voice recorder
    case voiceRecorder
}

/// Upload target tags representing the destination of an upload.
public enum PitagTargetEntity: Sendable {
    /// Not applicable or default target
    case notApplicable
    /// Target is Cloud Drive
    case cloudDrive
    /// Target is a 1-to-1 chat
    case chat1To1
    /// Target is a group chat
    case chatGroup
    /// Target is note to self
    case noteToSelf
    /// Target is an incoming share
    case incomingShare
    /// Target is multiple chats
    case multipleChats
}

/// Options for uploading files and folders to MEGA.
///
/// This struct encapsulates various configuration options for upload transfers,
/// including custom file naming, modification times, and upload behavior.
public struct UploadOptionsEntity: Sendable {
    
    /// Custom file or folder name in MEGA.
    ///
    /// If nil or empty, the name is taken from the local path.
    public let fileName: String?
    
    /// Custom modification time for files (seconds since epoch).
    ///
    /// Use `invalidCustomModTime` constant to keep the local mtime.
    public let mtime: Int64
    
    /// Custom app data associated with the transfer.
    ///
    /// Accessible via TransferEntity.appData.
    public let appData: String?
    
    /// If true, the the local file is deleted when the upload finishes.
    ///
    /// Intended for temporary files only.
    public let isSourceTemporary: Bool
    
    /// If true, the upload is put on top of the upload queue.
    public let startFirst: Bool
    
    /// Upload trigger tag representing the source of the upload action.
    public let pitagTrigger: PitagTriggerEntity
    
    /// Indicates if the upload is done to a chat.
    public let isChatUpload: Bool
    
    /// Upload target tag representing the destination.
    ///
    /// Apps uploading to chats should set the appropriate chat target (`.chat1To1`, `.chatGroup`, or `.noteToSelf`);
    /// for other uploads keep the default value to avoid interfering with internal logic.
    public let pitagTarget: PitagTargetEntity
    
    /// Constant representing an invalid custom modification time.
    ///
    /// Use this value to indicate that the local file's modification time should be preserved.
    public static let invalidCustomModTime: Int64 = -1
    
    // MARK: - Initializers
    
    /// Creates a new instance with all available options.
    ///
    /// - Parameters:
    ///   - fileName: The custom name for the file or folder in MEGA.
    ///   - mtime: Custom modification time (seconds since epoch).
    ///   - appData: Custom app data associated with the transfer.
    ///   - isSourceTemporary: If true, deletes the local file after upload.
    ///   - startFirst: If true, puts the upload at the top of the queue.
    ///   - pitagTrigger: Upload trigger tag.
    ///   - isChatUpload: Indicates if the upload is done to a chat.
    ///   - pitagTarget: Upload target tag.
    public init(
        fileName: String? = nil,
        mtime: Int64 = Self.invalidCustomModTime,
        appData: String? = nil,
        isSourceTemporary: Bool = true,
        startFirst: Bool = false,
        pitagTrigger: PitagTriggerEntity = .notApplicable,
        isChatUpload: Bool = false,
        pitagTarget: PitagTargetEntity = .notApplicable
    ) {
        self.fileName = fileName
        self.mtime = mtime
        self.appData = appData
        self.isSourceTemporary = isSourceTemporary
        self.startFirst = startFirst
        self.pitagTrigger = pitagTrigger
        self.isChatUpload = isChatUpload
        self.pitagTarget = pitagTarget
    }
}
