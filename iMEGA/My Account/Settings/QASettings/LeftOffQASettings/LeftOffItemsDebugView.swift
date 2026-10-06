import ContinueWhereYouLeftOff
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI
import UIKit

#if DEBUG || QA_CONFIG
/// Manual harness for exercising the Continue Where You Left Off data stack.
/// Drives the real shared-store use case from `ContinueWhereYouLeftOffFactory`, so fetching,
/// removing and the change signal all exercise the real store.
struct LeftOffItemsDebugView: View {
    @StateObject private var viewModel = LeftOffItemsDebugViewModel()

    var body: some View {
        Form {
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
        guard item.node.duration > 0 else { return "no duration" }
        return "duration \(item.node.duration)s"
    }

    private var statusSection: some View {
        Section("Status") {
            Text(viewModel.status).font(.footnote).foregroundStyle(.secondary)
        }
    }
}

@MainActor
final class LeftOffItemsDebugViewModel: ObservableObject {
    @Published var sortKey: LeftOffItemsSortKey = .lastAccessed
    @Published var ascending = false
    @Published private(set) var items: [ResolvedLeftOffItemEntity] = []
    @Published private(set) var status = "Idle"
    private var changesObserverTask: Task<Void, Never>?

    private let useCase: any LeftOffItemsUseCaseProtocol

    init(useCase: any LeftOffItemsUseCaseProtocol = LeftOffItemsDebugViewModel.makeUseCase()) {
        self.useCase = useCase
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
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            requestStatesRepository: RequestStatesRepository.newRepo
        )
    }

    private static func makeNodeUseCase() -> some NodeUseCaseProtocol {
        NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
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

    deinit {
        changesObserverTask?.cancel()
        changesObserverTask = nil
    }
}

#Preview {
    LeftOffItemsDebugView()
}
#endif
