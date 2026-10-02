import ContinueWhereYouLeftOff
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI
import UIKit

#if DEBUG || QA_CONFIG
/// Manual harness for exercising the Continue Where You Left Off data stack.
/// Drives the real shared-store use case from `ContinueWhereYouLeftOffFactory`, so recording,
/// fetching, removing and the change signal all exercise the real store.
struct CWYLODebugView: View {
    @StateObject private var viewModel = CWYLODebugViewModel()

    var body: some View {
        NavigationStack {
            Form {
                newItemSection
                fetchSection
                resultsSection
                statusSection
            }
            .navigationTitle("Continue Where You Left Off Debug")
            .navigationBarTitleDisplayMode(.inline)
            // `.task`, not `.onFirstLoad`: opening an item takes this screen off screen, which
            // cancels the task and ends the change subscription. This has to re-fetch and
            // re-subscribe on every appear, and `onFirstLoad` would refuse to run a second time.
            .task { await viewModel.start() }
        }
    }

    private var newItemSection: some View {
        Section("New item") {
            TextField("Handle (blank = random)", text: $viewModel.handleString)
                .keyboardType(.numberPad)
            TextField("Name (blank = node name)", text: $viewModel.name)
            Button("Record") {
                Task { await viewModel.record() }
            }
            Button("Record through LeftOffItemsRecorder") {
                Task { await viewModel.recordThroughRecorder() }
            }
        }
    }

    private var fetchSection: some View {
        Section("Fetch") {
            Picker("Sort by", selection: $viewModel.sortKey) {
                Text("Name").tag(LeftOffItemsSortKey.name)
                Text("Last accessed").tag(LeftOffItemsSortKey.lastAccessed)
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
        Section("Results (\(viewModel.items.count))") {
            if viewModel.items.isEmpty {
                Text("No items").foregroundStyle(.secondary)
            }
            ForEach(viewModel.items) { item in
                Button {
                    viewModel.open(item)
                } label: {
                    row(for: item)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.remove(item) }
                    }
                    Button("Unavailable") {
                        Task { await viewModel.removeUnavailable(item) }
                    }
                }
            }
        }
    }

    private func row(for item: ResolvedLeftOffItemEntity) -> some View {
        HStack {
            Image(systemName: item.isSensitive ? "eye.slash" : "doc")
            VStack(alignment: .leading, spacing: 2) {
                Text(item.item.name).font(.body)
                Text("handle \(item.item.handle)").font(.caption).foregroundStyle(.secondary)
                Text(durationText(for: item)).font(.caption).foregroundStyle(.secondary)
                Text(item.item.lastAccessed.formatted(date: .abbreviated, time: .standard))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func durationText(for item: ResolvedLeftOffItemEntity) -> String {
        guard let duration = item.duration else { return "no duration" }
        return "duration \(Int(duration))s"
    }

    private var statusSection: some View {
        Section("Status") {
            Text(viewModel.status).font(.footnote).foregroundStyle(.secondary)
        }
    }
}

@MainActor
final class CWYLODebugViewModel: ObservableObject {
    @Published var handleString = ""
    @Published var name = ""
    @Published var sortKey: LeftOffItemsSortKey = .lastAccessed
    @Published var ascending = false
    @Published private(set) var items: [ResolvedLeftOffItemEntity] = []
    @Published private(set) var status = "Idle"
    private var changesObserverTask: Task<Void, Never>?

    private let useCase: any LeftOffItemsUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol

    init(
        useCase: any LeftOffItemsUseCaseProtocol = CWYLODebugViewModel.makeUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = CWYLODebugViewModel.makeNodeUseCase()
    ) {
        self.useCase = useCase
        self.nodeUseCase = nodeUseCase
    }

    private static func makeUseCase() -> any LeftOffItemsUseCaseProtocol {
        let sensitiveNodeUseCase = SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
        )

        return ContinueWhereYouLeftOffFactory.makeLeftOffItemsUseCase(
            nodeUseCase: makeNodeUseCase(),
            sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                sensitiveNodeUseCase: sensitiveNodeUseCase,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                    repo: UserAttributeRepository.newRepo
                )
            ),
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
    }

    private static func makeNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    }

    /// Writes straight to the store, so a row can be created for a handle the recorder would reject.
    func record() async {
        let handle = resolvedHandle()
        let item = LeftOffItemEntity(handle: handle, name: resolvedName(for: handle), lastAccessed: .now)

        do {
            try await useCase.record(item)
            status = "Recorded handle \(handle)"
            await refreshAll()
        } catch {
            status = "Record failed: \(error)"
        }
    }

    /// Goes through the same path the players and viewers use, so the feature flag, sign-in and
    /// account-node guards are exercised too.
    func recordThroughRecorder() async {
        let handle = resolvedHandle()

        await LeftOffItemsRecorder.shared.record(handle: handle, name: resolvedName(for: handle))
        status = "Sent handle \(handle) to LeftOffItemsRecorder"
        await refreshAll()
    }

    func refreshAll() async {
        do {
            items = try await useCase.items(sortedBy: sortKey, ascending: ascending)
            status = "Fetched \(items.count)"
        } catch {
            status = "Fetch failed: \(error)"
        }
    }

    func fetchTop(limit: Int) async {
        do {
            items = try await useCase.topItems(limit: limit)
            status = "Fetched top \(items.count)"
        } catch {
            status = "Top fetch failed: \(error)"
        }
    }

    /// Opens the stored item through the same central opener the carousel will use, so a tap here
    /// goes through the app's real resume path.
    func open(_ item: ResolvedLeftOffItemEntity) {
        guard let navigationController = UIApplication.mnz_visibleViewController().navigationController else {
            status = "No navigation controller to open from"
            return
        }

        NodeOpener(navigationController: navigationController).openNode(nodeHandle: item.item.handle)
        status = "Opening handle \(item.item.handle)"
    }

    func remove(_ item: ResolvedLeftOffItemEntity) async {
        do {
            try await useCase.remove([item.item])
            status = "Removed handle \(item.item.handle)"
            await refreshAll()
        } catch {
            status = "Remove failed: \(error)"
        }
    }

    func removeUnavailable(_ item: ResolvedLeftOffItemEntity) async {
        do {
            try await useCase.removeUnavailable(item.item)
            status = "Removed unavailable handle \(item.item.handle)"
            await refreshAll()
        } catch {
            status = "Remove unavailable failed: \(error)"
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

    /// Loads the current contents, then follows the store for as long as the screen is up. The
    /// signal sequence never finishes, so the fetch has to come first, and the `.task` the view
    /// starts this on is what ends it.
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

    private func resolvedHandle() -> HandleEntity {
        UInt64(handleString) ?? UInt64.random(in: 1...UInt64.max)
    }

    private func resolvedName(for handle: HandleEntity) -> String {
        guard name.isEmpty else { return name }
        return nodeUseCase.nodeForHandle(handle)?.name ?? "Untitled"
    }

    deinit {
        changesObserverTask?.cancel()
        changesObserverTask = nil
    }
}

#Preview {
    CWYLODebugView()
}
#endif
