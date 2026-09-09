import Foundation
import MEGASdk

/// How `MockSdk` answers one `startUpload` call: which transfer delegate callbacks it fires on it,
/// and whether it fires them at all.
///
/// A batch upload is several transfers at once, each reporting on its own, so a test that drives
/// one needs to say what each of them does rather than stub a single result.
public enum MockUploadScript: Sendable {
    /// One transfer delegate callback of a scripted upload.
    public enum Event: Sendable {
        case start(isFolderTransfer: Bool = false)
        case update(stage: MEGATransferStage = .none)
        case folderUpdate(
            stage: MEGATransferStage,
            name: String = "",
            folderCount: UInt = 0,
            createdFolderCount: UInt = 0,
            fileCount: UInt = 0
        )
    }

    /// Fires `events` in order, then a successful finish.
    case events([Event])
    /// Fires nothing but a successful finish: an upload the SDK had nothing to say about.
    case silent
    /// Fires a finish carrying `errorType`, leaving the transfer in `state`.
    case failure(MEGAErrorType, state: MEGATransferState = .none)
    /// Fires nothing at all, and keeps the delegate for the test to drive through
    /// `MockSdk.drivenUploadDelegate(for:)`.
    case driven
}

/// An upload `MockSdk` is holding open, and the transfer delegate callbacks a test fires on it.
///
/// Handed out by `MockSdk.drivenUploadDelegate(for:)`. The delegate it holds is not `Sendable` --
/// no transfer delegate is -- so the handle stands in for it, and each callback is fired from
/// wherever the handle is read, which is what the SDK does with its own worker threads.
public struct MockDrivenUpload: @unchecked Sendable {
    /// The local path this upload was started with.
    public let localPath: String

    private let sdk: MEGASdk
    private let delegate: any MEGATransferDelegate

    init(localPath: String, sdk: MEGASdk, delegate: any MEGATransferDelegate) {
        self.localPath = localPath
        self.sdk = sdk
        self.delegate = delegate
    }

    public func fireStart(fileName: String, isFolderTransfer: Bool = false) {
        delegate.onTransferStart?(
            sdk,
            transfer: MockTransfer(type: .upload, fileName: fileName, isFolderTransfer: isFolderTransfer)
        )
    }

    public func fireUpdate(fileName: String, stage: MEGATransferStage = .none) {
        delegate.onTransferUpdate?(
            sdk,
            transfer: MockTransfer(type: .upload, fileName: fileName, stage: stage)
        )
    }

    public func fireFinish(
        fileName: String,
        errorType: MEGAErrorType = .apiOk,
        state: MEGATransferState = .none
    ) {
        delegate.onTransferFinish?(
            sdk,
            transfer: MockTransfer(type: .upload, fileName: fileName, state: state),
            error: MockError(errorType: errorType)
        )
    }

    public func fireFolderUpdate(
        stage: MEGATransferStage,
        name: String = "",
        folderCount: UInt = 0,
        createdFolderCount: UInt = 0,
        fileCount: UInt = 0
    ) {
        delegate.onFolderTransferUpdate?(
            sdk,
            transfer: MockTransfer(type: .upload, fileName: name, isFolderTransfer: true),
            stage: stage,
            folderCount: folderCount,
            createdFolderCount: createdFolderCount,
            fileCount: fileCount,
            currentFolder: name,
            currentFileLeafName: ""
        )
    }
}

/// What went wrong while a test drove `MockSdk`'s uploads.
public enum MockUploadError: Error {
    /// No upload was started for `path` before the test gave up waiting for one.
    case noUploadStarted(forPath: String)
}

/// Everything `MockSdk` keeps about the uploads it has been handed.
///
/// A class of its own, and locked, because a batch hands its items over from several tasks at
/// once, and a test reads them from several more.
final class MockUploadRecords: @unchecked Sendable {
    private let lock = NSLock()
    private var paths: [String] = []
    private var parentHandles: [UInt64] = []
    private var options: [MEGAUploadOptions] = []
    private var cancelTokens: [MEGACancelToken] = []
    private var drivenDelegates: [String: any MEGATransferDelegate] = [:]

    var startedPaths: [String] {
        lock.withLock { paths }
    }

    var startedParentHandles: [UInt64] {
        lock.withLock { parentHandles }
    }

    var startedOptions: [MEGAUploadOptions] {
        lock.withLock { options }
    }

    var startedCancelTokens: [MEGACancelToken] {
        lock.withLock { cancelTokens }
    }

    func record(path: String, parentHandle: UInt64, options uploadOptions: MEGAUploadOptions, cancelToken: MEGACancelToken?) {
        lock.withLock {
            paths.append(path)
            parentHandles.append(parentHandle)
            options.append(uploadOptions)
            if let cancelToken {
                cancelTokens.append(cancelToken)
            }
        }
    }

    func hold(_ delegate: any MEGATransferDelegate, forPath path: String) {
        lock.withLock { drivenDelegates[path] = delegate }
    }

    /// The delegate held for `key`, matched on the whole path first and on its last component
    /// after, so that a batch whose items are told apart by name alone can be driven by name.
    func heldDelegate(for key: String) -> (path: String, delegate: any MEGATransferDelegate)? {
        lock.withLock {
            if let delegate = drivenDelegates[key] { return (key, delegate) }
            return drivenDelegates
                .first { ($0.key as NSString).lastPathComponent == key }
                .map { ($0.key, $0.value) }
        }
    }
}
