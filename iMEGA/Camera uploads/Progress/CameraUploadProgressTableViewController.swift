import Combine
import MEGADesignToken
import MEGASwiftUI
import SwiftUI
import UIKit

final class CameraUploadProgressTableViewController: UITableViewController {
    private var dataSource: CameraUploadProgressDiffableDatasource?
    private let viewModel: CameraUploadProgressTableViewModel
    private var cancellables = Set<AnyCancellable>()
    private(set) var monitorCameraUploadsTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
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
    }
    
    private func setupBindings() {
        viewModel.$inProgressSnapshotUpdate
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak dataSource] in
                dataSource?.handleInProgressSnapshotUpdate($0)
            }
            .store(in: &cancellables)
    }
    
    private func setupTableView() {
        tableView.sectionHeaderTopPadding = 0
        tableView.backgroundColor = TokenColors.Background.page
        
        tableView.register(HostingTableViewCell<CameraUploadInProgressRowView>.self, forCellReuseIdentifier: "CameraUploadInProgressRowView")
        
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
                case .inProgress(let cameraUploadInProgressRowViewModel):
                    let cell = tableView.dequeueReusableCell(withIdentifier: "CameraUploadInProgressRowView", for: indexPath)
                    
                    cell.contentConfiguration = UIHostingConfiguration {
                        CameraUploadInProgressRowView(viewModel: cameraUploadInProgressRowViewModel)
                    }
                    .margins(.all, 0)
                    
                    return cell
                }
            }
        )
        
        dataSource?.defaultRowAnimation = .fade
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = CameraUploadProgressSections(rawValue: section) else {
            return nil
        }
        
        let headerView = UITableViewHeaderFooterView()
        headerView.contentConfiguration = UIHostingConfiguration {
            CameraUploadProgressSectionHeaderView(title: sectionType.title)
        }
        .margins(.all, 0)
        
        return headerView
    }
}
