import MEGAMarkdown
import MEGAMarkdownEditor
import SwiftUI
import UIKit

/// Shows one test file in the preview or as read-only source.
struct FileScreen: View {
    let entry: TestFileEntry
    /// 0-based line to open at. Nil opens at the line this file showed last time.
    let restoreLine: Int?
    /// The capture mode turns this off, so every capture starts at the top.
    let usesSavedLine: Bool

    @AppStorage(SettingsKey.gitHubBaseURL) private var gitHubBaseURL = SettingsDefault.gitHubBaseURL
    @State private var mode = FileScreenMode.preview
    @State private var content: FileContent?
    @State private var imageMode: ImageMode
    @State private var softBreak: SoftBreakMode
    @State private var topLine = 0
    @State private var gitHubPage: URL?
    /// The text in the editor. The editor writes it back to the file.
    @State private var editedText = ""
    @State private var saveError: String?
    /// Read once. The preview saves a new line on every report, and a live value would jump the list back to it.
    @State private var startLine: Int?

    init(entry: TestFileEntry, restoreLine: Int? = nil, usesSavedLine: Bool = true) {
        self.entry = entry
        self.restoreLine = restoreLine
        self.usesSavedLine = usesSavedLine
        _startLine = State(initialValue: restoreLine ?? (usesSavedLine ? SavedLines.line(for: entry.url) : nil))
        // Each test case opens with the options it needs. The menu can still change them.
        _imageMode = State(initialValue: ImageMode.forTestCase(entry.relativePath))
        _softBreak = State(initialValue: SoftBreakMode.forTestCase(entry.relativePath))
    }

    var body: some View {
        Group {
            switch content {
            case nil:
                ProgressView()
            case .tooLarge:
                Text(MarkdownPreviewStrings.english.tooLarge)
                    .multilineTextAlignment(.center)
                    .padding()
            case .unreadable:
                Text("This file is not valid UTF-8 or cannot be read. The demo does not open it, so it cannot overwrite it.")
                    .multilineTextAlignment(.center)
                    .padding()
            case .text(let text):
                switch mode {
                case .preview:
                    MarkdownPreview(
                        text,
                        baseURL: entry.url.deletingLastPathComponent(),
                        softBreak: softBreak.value,
                        restoreLine: startLine
                    ) { position in
                        let line = position.topLine
                        topLine = line
                        if usesSavedLine {
                            SavedLines.save(line, for: entry.url)
                        }
                    }
                    .markdownImageLoading(imageMode.loading)
                case .source:
                    SourceTextView(text: text)
                case .richEditor, .sourceEditor:
                    MarkdownEditor(
                        // Saves in the setter, so the last edit is written even when this view leaves at once.
                        markdown: Binding(get: { editedText }, set: { editedText = $0; save($0) }),
                        mode: Binding(get: { mode == .richEditor ? .rich : .source }, set: { mode = $0 == .rich ? .richEditor : .sourceEditor }),
                        baseURL: entry.url.deletingLastPathComponent()
                    )
                    .markdownImageLoading(imageMode.loading)
                }
            }
        }
        // Keeps the status bar at the bottom while a short message shows.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            statusBar
        }
        .toolbar { toolbarContent }
        // A push, not a sheet: the preview stays in the stack and its load is cancelled and started again.
        .navigationDestination(item: $gitHubPage) { url in
            SafariView(url: url) { gitHubPage = nil }
                .ignoresSafeArea()
                // The page has its own close button. A second back button would show above it.
                .navigationBarBackButtonHidden()
        }
        .task {
            guard content == nil else { return }
            await reload()
        }
    }

    private var statusBar: some View {
        HStack {
            if let saveError {
                Text(saveError)
                    .foregroundStyle(.red)
            }
            Text(entry.byteCount.formatted(.byteCount(style: .file)))
            Spacer()
            Text("Top line \(topLine + 1)")
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.bar)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(mode == .preview ? "Source" : "Preview") {
                mode = mode == .preview ? .source : .preview
            }
            Button("Edit") {
                mode = .richEditor
            }
            .disabled(mode == .richEditor || mode == .sourceEditor || !isText)
            if entry.isTestFile, let url = gitHubURL {
                Button("GitHub") {
                    gitHubPage = url
                }
            }
            Menu("Options", systemImage: "ellipsis.circle") {
                Picker("Mode", selection: $mode) {
                    ForEach(FileScreenMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                Picker("Images", selection: $imageMode) {
                    ForEach(ImageMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                Picker("Soft break", selection: $softBreak) {
                    ForEach(SoftBreakMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }
        }
    }

    /// Writes the edited text to the file, so the preview and the next open show it.
    /// A synced test file is replaced again by the next Sync.
    private func save(_ text: String) {
        do {
            try text.write(to: entry.url, atomically: true, encoding: .utf8)
            saveError = nil
            content = .text(text)
        } catch {
            saveError = "Save failed: \(error.localizedDescription)"
        }
    }

    private var isText: Bool {
        if case .text = content { return true }
        return false
    }

    private func reload() async {
        let loaded = await FileContent.load(entry.url)
        // The editor must start with the file text, so mounting it writes nothing.
        if case .text(let text) = loaded { editedText = text }
        content = loaded
    }

    /// The base URL plus the file path below `TestFiles`, one percent-encoded part at a time.
    private var gitHubURL: URL? {
        let base = gitHubBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else { return nil }
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        let path = entry.relativePath
            .split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: allowed) ?? String($0) }
            .joined(separator: "/")
        let trimmedBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        return URL(string: trimmedBase + "/" + path)
    }
}

enum FileScreenMode: CaseIterable {
    case preview
    case source
    case richEditor
    case sourceEditor

    var title: String {
        switch self {
        case .preview: "Preview"
        case .source: "Source (read-only)"
        case .richEditor: "Rich editor"
        case .sourceEditor: "Source editor"
        }
    }
}

enum ImageMode: CaseIterable {
    case altText
    case remote
    case localFiles

    var title: String {
        switch self {
        case .altText: "Alt text only"
        case .remote: "Load remote images"
        case .localFiles: "Load local files"
        }
    }

    /// Remote images for the remote cases. Local files everywhere else, so relative image links show.
    static func forTestCase(_ path: String) -> ImageMode {
        path.hasPrefix("images/remote/") ? .remote : .localFiles
    }

    var loading: MarkdownImageLoading {
        switch self {
        case .altText:
            .altTextOnly
        case .remote:
            .remote
        case .localFiles:
            // Relative image paths resolve against the file's folder, so they arrive here as file URLs.
            .provided { url in
                url.isFileURL ? UIImage(contentsOfFile: url.path) : nil
            }
        }
    }
}

enum SoftBreakMode: CaseIterable {
    case lineBreak
    case space

    var title: String {
        switch self {
        case .lineBreak: "Line break (Android)"
        case .space: "Space (CommonMark)"
        }
    }

    /// The spec examples expect the CommonMark soft break. The other cases use the Android one.
    static func forTestCase(_ path: String) -> SoftBreakMode {
        path.hasPrefix("commonmark-spec/") || path.hasPrefix("gfm-spec/") ? .space : .lineBreak
    }

    var value: MarkdownSoftBreak {
        switch self {
        case .lineBreak: .lineBreak
        case .space: .space
        }
    }
}

/// The text of a file, or a note that it is too large to read.
enum FileContent: Equatable, Sendable {
    case text(String)
    case tooLarge
    case unreadable

    /// Reads off the main thread. A file that is not valid UTF-8 is unreadable, so it is never written back.
    @concurrent
    static func load(_ url: URL) async -> FileContent {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        guard size <= MarkdownPreview.sizeLimitInBytes else { return .tooLarge }
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { return .unreadable }
        return .text(text)
    }
}
