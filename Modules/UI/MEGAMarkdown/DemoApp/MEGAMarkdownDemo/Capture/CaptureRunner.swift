import UIKit

/// Saves screenshots of each test file to `Documents/Captures`, then writes `index.json`.
/// The PNG name is the file path with "/" replaced by "__", plus the screen number.
@MainActor
final class CaptureRunner {
    private let config: CaptureConfig
    private let output: URL

    init(config: CaptureConfig) {
        self.config = config
        output = URL.documentsDirectory.appending(path: "Captures")
    }

    struct Record: Encodable {
        let path: String
        let pages: Int
        /// From opening the file to the first rows in the list. 0 when the file shows no list.
        let firstRowsMilliseconds: Int
        let loadMilliseconds: Int
        let hasList: Bool
    }

    func run(show: (TestFileEntry?) -> Void) async {
        try? FileManager.default.removeItem(at: output)
        try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var records: [Record] = []
        for entry in Self.markdownFiles() where entry.relativePath.hasPrefix(config.prefix) {
            // An empty screen between files, so each file starts with a new list.
            show(nil)
            for _ in 0..<100 where previewList() != nil {
                try? await Task.sleep(for: .milliseconds(20))
            }
            show(entry)
            let start = ContinuousClock.now
            await waitForFirstRows()
            let firstRowsTime = ContinuousClock.now - start
            await waitUntilSettled(remote: entry.relativePath.hasPrefix("images/remote/"))
            let loadTime = ContinuousClock.now - start
            let pages = await savePages(of: entry)
            records.append(Record(
                path: entry.relativePath,
                pages: pages,
                firstRowsMilliseconds: previewList() == nil ? 0 : Int(firstRowsTime / .milliseconds(1)),
                loadMilliseconds: Int(loadTime / .milliseconds(1)),
                hasList: previewList() != nil
            ))
            print("CAPTURED \(records.count) \(entry.relativePath) pages=\(pages)")
        }
        show(nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? encoder.encode(records).write(to: output.appending(path: "index.json"))
        print("CAPTURE DONE \(records.count)")
    }

    /// Every Markdown file below `TestFiles`, sorted by path.
    private static func markdownFiles() -> [TestFileEntry] {
        guard let root = TestFileEntry.root,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey]) else { return [] }
        let urls = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "md" }
        return urls
            .map { url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return TestFileEntry(url: url, isFolder: false, byteCount: size)
            }
            .sorted { $0.relativePath < $1.relativePath }
    }

    /// Waits until the list has rows. A file with no list (too large, or not text) stops after 10 s.
    private func waitForFirstRows() async {
        for _ in 0..<500 {
            if let list = previewList(), list.numberOfSections > 0, list.numberOfItems(inSection: 0) > 0 { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    /// Waits until the list content height stops changing. Remote images get extra time to download.
    private func waitUntilSettled(remote: Bool) async {
        try? await Task.sleep(for: .milliseconds(remote ? 5000 : 500))
        var lastHeight: CGFloat = -1
        var stableCount = 0
        // Stops after 10 s, so one stuck file does not stop the run.
        for _ in 0..<100 {
            let height = previewList()?.contentSize.height ?? 0
            stableCount = height == lastHeight ? stableCount + 1 : 0
            if stableCount >= 3 { return }
            lastHeight = height
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private func savePages(of entry: TestFileEntry) async -> Int {
        let baseName = entry.relativePath.replacingOccurrences(of: "/", with: "__")
        guard let list = previewList() else {
            save(name: "\(baseName).p1.png")
            return 1
        }
        let top = -list.adjustedContentInset.top
        let pageHeight = max(list.bounds.height - list.adjustedContentInset.top - list.adjustedContentInset.bottom, 100)
        var page = 0
        var lastOffset = -CGFloat.infinity
        while page < config.maxPages {
            // The last screen stops at the end of the content, so it can overlap the screen before it.
            let maxOffset = max(list.contentSize.height + list.adjustedContentInset.bottom - list.bounds.height, top)
            let offset = min(top + CGFloat(page) * pageHeight, maxOffset)
            if offset <= lastOffset + 1 { break }
            lastOffset = offset
            list.setContentOffset(CGPoint(x: list.contentOffset.x, y: offset), animated: false)
            if page > 0 {
                await waitUntilSettled(remote: false)
            }
            save(name: "\(baseName).p\(page + 1).png")
            page += 1
        }
        return page
    }

    private func save(name: String) {
        guard let window = Self.window() else { return }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try? image.pngData()?.write(to: output.appending(path: name))
    }

    /// The preview's row list: the tallest collection view on screen. Code and table rows have smaller scroll views.
    private func previewList() -> UICollectionView? {
        guard let window = Self.window() else { return nil }
        var found: [UICollectionView] = []
        var stack: [UIView] = [window]
        while let view = stack.popLast() {
            if let list = view as? UICollectionView, list.window != nil, !list.isHidden {
                found.append(list)
            }
            stack.append(contentsOf: view.subviews)
        }
        return found.max { $0.bounds.height < $1.bounds.height }
    }

    private static func window() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }
}
