import Foundation
import Observation

/// Copies the test-file repo into `Documents/TestFiles`, so a pushed change needs no new build.
/// A sync downloads only the files whose Git hash changed, and removes the files that left the repo.
/// The repo is public, so no token is needed. One sync makes one GitHub API call.
@MainActor
@Observable
final class TestFilesSync {
    nonisolated static let repository = "mega-bl/markdown-test-files"
    nonisolated static let branch = "main"
    /// GitHub rejects files over 100 MB, so the repo has no file over the preview size limit. The app writes it.
    nonisolated static let overLimitPath = "large-files/too-large-101mib-over-limit.md"

    enum State: Equatable {
        case idle
        case syncing(done: Int, total: Int)
        case failed(String)
    }

    private(set) var state = State.idle
    /// Grows after each sync, so the folder screens list the files again.
    private(set) var generation = 0

    var isSyncing: Bool {
        if case .syncing = state { true } else { false }
    }

    func run() async {
        guard !isSyncing else { return }
        state = .syncing(done: 0, total: 0)
        do {
            try await sync()
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
        generation += 1
    }

    private func sync() async throws {
        let root = TestFileEntry.syncedRoot
        let files = try await Self.repositoryFiles()
        var manifest = Self.readManifest()
        let changed = files.filter { manifest[$0.path] != $0.sha }
        for path in manifest.keys where !files.contains(where: { $0.path == path }) {
            try? FileManager.default.removeItem(at: root.appending(path: path))
            manifest[path] = nil
        }
        state = .syncing(done: 0, total: changed.count)
        var done = 0
        var failure: (any Error)?
        // Four downloads at a time. Each one writes its file before the next one starts.
        await withThrowingTaskGroup(of: RepositoryFile.self) { group in
            var pending = changed[...]
            func addNext() {
                guard let file = pending.popFirst() else { return }
                group.addTask { try await Self.download(file, into: root) }
            }
            for _ in 0..<4 { addNext() }
            while let result = await group.nextResult() {
                switch result {
                case .success(let file):
                    manifest[file.path] = file.sha
                    done += 1
                    state = .syncing(done: done, total: changed.count)
                case .failure(let error):
                    failure = failure ?? error
                }
                if !Task.isCancelled { addNext() }
            }
        }
        // Saved also after a failure, so the next sync skips the files that arrived.
        Self.writeManifest(manifest)
        try await Self.writeOverLimitFile(in: root)
        if let failure { throw failure }
    }

    // MARK: - GitHub

    struct RepositoryFile: Sendable {
        let path: String
        let sha: String
    }

    private struct TreeResponse: Decodable {
        struct Item: Decodable {
            let path: String
            let type: String
            let sha: String
        }

        let tree: [Item]
        let truncated: Bool
    }

    private struct SyncError: LocalizedError {
        let errorDescription: String?
    }

    /// Every file of the branch, from one call to the Git trees API.
    private nonisolated static func repositoryFiles() async throws -> [RepositoryFile] {
        let url = try url("https://api.github.com/repos/\(repository)/git/trees/\(branch)?recursive=1")
        let (data, response) = try await URLSession.shared.data(from: url)
        try check(response, for: "the file list")
        let tree = try JSONDecoder().decode(TreeResponse.self, from: data)
        guard !tree.truncated else { throw SyncError(errorDescription: "GitHub sent only part of the file list.") }
        return tree.tree
            .filter { $0.type == "blob" && !$0.path.hasPrefix(".") }
            .map { RepositoryFile(path: $0.path, sha: $0.sha) }
    }

    /// The raw file goes to a temporary file first, so a big file is never held in memory.
    private nonisolated static func download(_ file: RepositoryFile, into root: URL) async throws -> RepositoryFile {
        let url = try url("https://raw.githubusercontent.com/\(repository)/\(branch)/\(encoded(file.path))")
        let (temporary, response) = try await URLSession.shared.download(from: url)
        try check(response, for: file.path)
        let destination = root.appending(path: file.path)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporary, to: destination)
        return file
    }

    private nonisolated static func check(_ response: URLResponse, for name: String) throws {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw SyncError(errorDescription: "GitHub answered \(status) for \(name).") }
    }

    private nonisolated static func url(_ string: String) throws -> URL {
        guard let url = URL(string: string) else { throw SyncError(errorDescription: "Bad URL \(string)") }
        return url
    }

    /// Each path part percent-encoded, so names with spaces or other scripts work.
    private nonisolated static func encoded(_ path: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        return path
            .split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: allowed) ?? String($0) }
            .joined(separator: "/")
    }

    // MARK: - Local files

    /// Outside `TestFiles`, so the folder screens do not list it.
    private static let manifestURL = URL.documentsDirectory.appending(path: "TestFiles-manifest.json")

    /// Path to Git hash of every file the last syncs wrote.
    private static func readManifest() -> [String: String] {
        guard let data = try? Data(contentsOf: manifestURL) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    private static func writeManifest(_ manifest: [String: String]) {
        try? JSONEncoder().encode(manifest).write(to: manifestURL, options: .atomic)
    }

    /// 101 MiB of paragraphs, written 1 MiB at a time. The preview shows its "too large" message for it.
    @concurrent
    private nonisolated static func writeOverLimitFile(in root: URL) async throws {
        let url = root.appending(path: overLimitPath)
        let megabyte = 1024 * 1024
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard size <= 100 * megabyte else { return }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let line = "A paragraph that makes this file bigger than the preview size limit.\n\n"
        let chunk = Data(String(repeating: line, count: megabyte / line.utf8.count + 1).utf8.prefix(megabyte))
        FileManager.default.createFile(atPath: url.path, contents: nil)
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        for _ in 0..<101 {
            try handle.write(contentsOf: chunk)
        }
    }
}
