import MEGASwift
import MEGASwiftUI
import SwiftUI
import ViewedLinks

#if DEBUG || QA_CONFIG
/// Manual harness for exercising the Viewed Links data stack.
/// Drives the real shared-store use case from `ViewedLinksFactory`, so recording,
/// fetching, removing and the change signal all exercise the real store.
struct ViewedLinksDebugView: View {
    @StateObject private var viewModel = ViewedLinksDebugViewModel()

    var body: some View {
        NavigationStack {
            Form {
                newLinkSection
                fetchSection
                resultsSection
                statusSection
            }
            .navigationTitle("Viewed Links Debug")
            // `.task`, not `.onFirstLoad`: opening a link takes this screen off screen, which cancels
            // the task and ends the change subscription. This has to re-fetch and re-subscribe on
            // every appear, and `onFirstLoad` would refuse to run a second time.
            .task { await viewModel.start() }
        }
    }

    private var newLinkSection: some View {
        Section("New link") {
            TextField("Name", text: $viewModel.name)
            TextField("Link URL", text: $viewModel.urlString)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Handle (blank = random)", text: $viewModel.handleString)
                .keyboardType(.numberPad)
            Toggle("Is folder", isOn: $viewModel.isFolder)
            Button("Record") {
                Task { await viewModel.record() }
            }
        }
    }

    private var fetchSection: some View {
        Section("Fetch") {
            Picker("Sort by", selection: $viewModel.sortKey) {
                Text("Name").tag(ViewedLinksSortKey.name)
                Text("Last accessed").tag(ViewedLinksSortKey.lastAccessed)
            }
            Toggle("Ascending", isOn: $viewModel.ascending)
            Button("Fetch all") {
                Task { await viewModel.refreshAll() }
            }
            Button("Fetch top 5") {
                Task { await viewModel.fetchTop(limit: 5) }
            }
            Button("Clear history", role: .destructive) {
                Task { await viewModel.clearHistory() }
            }
        }
    }

    private var resultsSection: some View {
        Section("Results (\(viewModel.links.count))") {
            if viewModel.links.isEmpty {
                Text("No links").foregroundStyle(.secondary)
            }
            ForEach(viewModel.links, id: \.handle) { link in
                Button {
                    viewModel.open(link)
                } label: {
                    row(for: link)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.remove(link) }
                    }
                    Button("By URL") {
                        Task { await viewModel.removeUnavailable(link) }
                    }
                }
            }
        }
    }

    private func row(for link: ViewedLinkEntity) -> some View {
        HStack {
            Image(systemName: link.isFolder ? "folder" : "doc")
            VStack(alignment: .leading, spacing: 2) {
                Text(link.name).font(.body)
                Text(link.linkURL.absoluteString)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                Text("handle \(link.handle)").font(.caption).foregroundStyle(.secondary)
                Text(link.lastAccessed.formatted(date: .abbreviated, time: .standard))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Text(viewModel.status).font(.footnote).foregroundStyle(.secondary)
        }
    }
}

@MainActor
final class ViewedLinksDebugViewModel: ObservableObject {
    @Published var name = ""
    @Published var urlString = "https://mega.nz/file/debug"
    @Published var handleString = ""
    @Published var isFolder = false
    @Published var sortKey: ViewedLinksSortKey = .lastAccessed
    @Published var ascending = false
    @Published private(set) var links: [ViewedLinkEntity] = []
    @Published private(set) var status = "Idle"
    private var changesObserverTask: Task<Void, Never>?
    
    /// Mirrors `OpenLinkRouter.supportedLinkTypes`. `.encryptedLink` matters here because a
    /// password-protected link is stored in its original `#P!` form, so re-opening it re-prompts
    /// for the password rather than handing back a decrypted link.
    private static let supportedLinkTypes: Set<URLType> = [
        .fileLink,
        .folderLink,
        .encryptedLink,
        .collection,
        .contactLink,
        .publicChatLink
    ]
    
    private let useCase: any ViewedLinksUseCaseProtocol
    
    init(useCase: some ViewedLinksUseCaseProtocol = ViewedLinksFactory.makeViewedLinksUseCase()) {
        self.useCase = useCase
    }
    
    func record() async {
        guard let url = URL(string: urlString) else {
            status = "Invalid URL"
            return
        }
        let handle = UInt64(handleString) ?? UInt64.random(in: 1...UInt64.max)
        let link = ViewedLinkEntity(
            handle: handle,
            linkURL: url,
            name: name.isEmpty ? "Untitled" : name,
            isFolder: isFolder,
            hasThumbnail: false,
            lastAccessed: .now
        )
        do {
            try await useCase.record(link)
            status = "Recorded handle \(handle)"
            await refreshAll()
        } catch {
            status = "Record failed: \(error)"
        }
    }
    
    func refreshAll() async {
        do {
            links = try await useCase.viewedLinks(sortedBy: sortKey, ascending: ascending)
            status = "Fetched \(links.count)"
        } catch {
            status = "Fetch failed: \(error)"
        }
    }
    
    func fetchTop(limit: Int) async {
        do {
            links = try await useCase.topViewedLinks(limit: limit)
            status = "Fetched top \(links.count)"
        } catch {
            status = "Top fetch failed: \(error)"
        }
    }
    
    /// Opens the stored link exactly as `OpenLinkRouter.processLink(_:)` does, so a tap here goes
    /// through the same routing the app uses for a link typed into Open link.
    func open(_ link: ViewedLinkEntity) {
        let url = link.linkURL
        guard Self.supportedLinkTypes.contains((url as NSURL).mnz_type()) else {
            status = "Unsupported link type \((url as NSURL).mnz_type().rawValue): \(url.absoluteString)"
            return
        }
        
        MEGALinkManager.adapterLinkURL = url
        MEGALinkManager.processLinkURL(url)
        status = "Opening \(url.absoluteString)"
    }
    
    func remove(_ link: ViewedLinkEntity) async {
        do {
            try await useCase.remove([link])
            status = "Removed handle \(link.handle)"
            await refreshAll()
        } catch {
            status = "Remove failed: \(error)"
        }
    }
    
    func removeUnavailable(_ link: ViewedLinkEntity) async {
        do {
            try await useCase.removeUnavailable(linkURL: link.linkURL)
            status = "Removed by URL \(link.linkURL.absoluteString)"
            await refreshAll()
        } catch {
            status = "Remove by URL failed: \(error)"
        }
    }
    
    func clearHistory() async {
        do {
            try await useCase.clearHistory()
            status = "Cleared history"
            await refreshAll()
        } catch {
            status = "Clear failed: \(error)"
        }
    }
    
    /// Loads the current contents, then follows the store for as long as the screen is up. The signal
    /// sequence never finishes, so the fetch has to come first, and the `.task` the view starts this
    /// on is what ends it.
    func start() async {
        await refreshAll()
        await observeChanges()
    }

    private func observeChanges() async {
        guard changesObserverTask == nil else { return }

        changesObserverTask = Task { [weak self, useCase] in
            for await _ in useCase.changesSignalSequence() {
                await self?.refreshAll()
            }
        }
    }

    deinit {
        changesObserverTask?.cancel()
        changesObserverTask = nil
    }
}

#Preview {
    ViewedLinksDebugView()
}
#endif
