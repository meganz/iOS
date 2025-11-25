import Combine
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI
import UIKit

final class CameraUploadProgressTableViewController: UITableViewController {
    private enum ReuseIdentifiers {
        static let inProgressRow = "CameraUploadInProgressRowView"
        static let inQueueRow = "CameraUploadInQueueRowView"
        static let emptyInProgressRow = "EmptyInProgressRowView"
        static let emptyInQueueRow = "EmptyInQueueRowView"
        static let skeletonRow = "SkeletonRowView"
    }
    private var dataSource: CameraUploadProgressDiffableDatasource?
    private let viewModel: CameraUploadProgressTableViewModel
    private var cancellables = Set<AnyCancellable>()
    private(set) var monitorCameraUploadsTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var scrollDebounceTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var lastScrollOffset: CGFloat = 0
    
    init(viewModel: CameraUploadProgressTableViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        configureDataSource()
        setupBindings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        monitorCameraUploadsTask = Task {
            await viewModel.loadInitial()
            await viewModel.monitorActiveUploads()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        monitorCameraUploadsTask = nil
        scrollDebounceTask = nil
        lastScrollOffset = 0
    }
    
    private func setupBindings() {
        viewModel.$snapshotUpdate
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak dataSource] in
                dataSource?.handleSnapshotUpdate($0)
            }
            .store(in: &cancellables)
    }
    
    private func setupTableView() {
        tableView.sectionHeaderTopPadding = 0
        tableView.backgroundColor = TokenColors.Background.page
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelection = false
        
        tableView.register(HostingTableViewCell<CameraUploadInProgressRowView>.self, forCellReuseIdentifier: ReuseIdentifiers.inProgressRow)
        tableView.register(HostingTableViewCell<CameraUploadInQueueRowView>.self, forCellReuseIdentifier: ReuseIdentifiers.inQueueRow)
        tableView.register(HostingTableViewCell<CameraUploadProgressEmptyRowView>.self, forCellReuseIdentifier: ReuseIdentifiers.emptyInProgressRow)
        tableView.register(HostingTableViewCell<CameraUploadProgressEmptyRowView>.self, forCellReuseIdentifier: ReuseIdentifiers.emptyInQueueRow)
        tableView.register(HostingTableViewCell<CameraUploadProgressSkeletonRowView>.self, forCellReuseIdentifier: ReuseIdentifiers.skeletonRow)
        
        tableView.rowHeight = viewModel.rowHeight
        tableView.estimatedRowHeight = viewModel.rowHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 36
        tableView.separatorStyle = .none
    }
    
    private func configureDataSource() {
        dataSource = CameraUploadProgressDiffableDatasource(
            tableView: tableView,
            cellProvider: { (tableView: UITableView, indexPath: IndexPath, row: CameraUploadProgressSectionRow) -> UITableViewCell in
                switch row {
                case .loading:
                    let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.inProgressRow, for: indexPath)
                    
                    cell.contentConfiguration = UIHostingConfiguration {
                        CameraUploadProgressSkeletonRowView()
                    }
                    .margins(.all, 0)
                    
                    return cell
                case .inProgress(let cameraUploadInProgressRowViewModel):
                    let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.inProgressRow, for: indexPath)
                    
                    cell.contentConfiguration = UIHostingConfiguration {
                        CameraUploadInProgressRowView(viewModel: cameraUploadInProgressRowViewModel)
                    }
                    .margins(.all, 0)
                    
                    return cell
                case .inQueue(let cameraUploadInQueueRowViewModel):
                    let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.inQueueRow, for: indexPath)
                    
                    cell.contentConfiguration = UIHostingConfiguration {
                        CameraUploadInQueueRowView(viewModel: cameraUploadInQueueRowViewModel)
                    }
                    .margins(.all, 0)
                    
                    return cell
                case .emptyInProgress:
                    let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.emptyInProgressRow, for: indexPath)
                    
                    cell.contentConfiguration = UIHostingConfiguration {
                        CameraUploadProgressEmptyRowView(
                            title: Strings.Localizable.CameraUploads.Progress.Row.EmptyInProgress.title)
                    }
                    .margins(.all, 0)
                    
                    return cell
                case .emptyInQueue:
                    let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.emptyInQueueRow, for: indexPath)
                    
                    cell.contentConfiguration = UIHostingConfiguration {
                        CameraUploadProgressEmptyRowView(
                            title: Strings.Localizable.CameraUploads.Progress.Row.EmptyInQueue.title)
                    }
                    .margins(.all, 0)
                    
                    return cell
                }
            }
        )
        
        dataSource?.defaultRowAnimation = .none
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let dataSource = dataSource,
              let sectionType = dataSource.snapshot().sectionIdentifiers[safe: section] else {
            return nil
        }
        
        let headerView = UITableViewHeaderFooterView()
        headerView.contentConfiguration = UIHostingConfiguration {
            switch sectionType {
            case .loadingInProgress, .loadingInQueue:
                CameraUploadProgressSkeletonHeaderView()
            case .inProgress, .inQueue:
                CameraUploadProgressSectionHeaderView(title: sectionType.title)
            }
        }
        .margins(.all, 0)
        
        return headerView
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let offsetDelta = abs(currentOffset - lastScrollOffset)
        
        let scrollThreshold = viewModel.rowHeight * 0.5
        guard offsetDelta > scrollThreshold else { return }
        
        let isUserInitiated = scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating
        guard !viewModel.isPaginationInProgress else { return }
        
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows,
              !visibleIndexPaths.isEmpty,
              let items = dataSource?.snapshot().itemIdentifiers(inSection: .inQueue),
              !items.isEmpty else { return }
        
        let queueIndexPaths = visibleIndexPaths.filter { $0.section == CameraUploadProgressSections.inQueue.rawValue }
        guard !queueIndexPaths.isEmpty else { return }
        
        let middleQueueIndexPath = queueIndexPaths[queueIndexPaths.count / 2]
        let middleIndex = middleQueueIndexPath.row
        let totalItems = items.count
        
        lastScrollOffset = currentOffset
        
        scrollDebounceTask = Task { @MainActor [weak viewModel] in
            guard let viewModel else { return }
            
            if !viewModel.isNearEdge(visibleIndex: middleIndex, totalItems: totalItems) {
                try? await Task.sleep(nanoseconds: 150_000_000) // 150ms debounce
                guard !Task.isCancelled else { return }
            }
            
            await viewModel.handleQueueSectionScroll(
                visibleIndex: middleIndex,
                totalVisibleItems: totalItems,
                isUserInitiated: isUserInitiated
            )
        }
    }
}
