import Foundation

final class TableViewProxy<CellItem> :
    NSObject,
    UITableViewDataSource,
    UITableViewDelegate,
    DZNEmptyDataSetSource {

    typealias DataSourceConfigurationGenerator
        = ([CellItem]) -> TableDataSourceConfiguration<CellItem>

    private var cellConfiguration: CellConfiguration
    
    private var emptyStateConfiguration: EmptyStateConfiguration?
    
    private var dataSourceConfiguration: TableDataSourceConfiguration<CellItem>?
    
    var selectionAction: ((CellItem) -> Void)?

    var configureCell: ((UITableViewCell, CellItem) -> Void)

    init(
        cellIdentifier: String,
        emptyStateConfiguration: EmptyStateConfiguration? = nil,
        configureCell: (@escaping (UITableViewCell, CellItem) -> Void),
        selectionAction: ((CellItem) -> Void)? = nil
    ) {
        self.cellConfiguration = .init(cellIdentifier: cellIdentifier)
        self.emptyStateConfiguration = emptyStateConfiguration
        self.configureCell = configureCell
        self.selectionAction = selectionAction
    }
    
    // MARK: - Public Interface

    func attachTo(_ tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        cellConfiguration.registerCell(in: tableView)

        if nil != emptyStateConfiguration {
            tableView.emptyDataSetSource = self
            tableView.tableFooterView = UIView()
        }
    }

    func reload(
        _ tableView: UITableView,
        withData newData: [CellItem],
        configurationFactory: TableDataSourceConfigurationFactory<CellItem> = .simple
    ) {
        assert(tableView.dataSource === self, "Reloading a table view whose data source is not \(self)")
        self.dataSourceConfiguration = configurationFactory.produce(newData)
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        dataSourceConfiguration?.numberOfSections() ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSourceConfiguration?.numberOfRows(section) ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cellConfiguration.dequeuedCell(in: tableView, for: indexPath)
        if let cellItem = dataSourceConfiguration?.itemAtIndexPath(indexPath) {
            configureCell(cell, cellItem)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let selectedItem = dataSourceConfiguration?.itemAtIndexPath(indexPath) {
            selectionAction?(selectedItem)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        dataSourceConfiguration?.headerTitle(section)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.window?.endEditing(true)
    }

    // MARK: - DZNEmptyDataSetSource

    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        emptyStateConfiguration?.emptyStateView()
    }
}

extension TableViewProxy where CellItem: Comparable {

    func reload(
        _ tableView: UITableView,
        withData newData: [CellItem],
        asc: Bool
    ) {
        assert(tableView.dataSource === self, "Reloading a table view whose data source is not \(self)")
        let configurationFactory: TableDataSourceConfigurationFactory<CellItem> =
            asc ? .sorted(.ordering(CellItem.self)) : .sorted(.ordering(CellItem.self, sortingItems: .desc))
        self.dataSourceConfiguration = configurationFactory.produce(newData)
        tableView.reloadData()
    }

    func reload(
        _ tableView: UITableView,
        withData newData: [CellItem],
        ordering: Reader<[CellItem], [CellItem]> = .ordering(CellItem.self)
    ) {
        assert(tableView.dataSource === self, "Reloading a table view whose data source is not \(self)")
        let configurationFactory: TableDataSourceConfigurationFactory<CellItem> = .sorted(ordering)
        self.dataSourceConfiguration = configurationFactory.produce(newData)
        tableView.reloadData()
    }
}

extension TableViewProxy where CellItem: Comparable & Aggregatable, CellItem.Key: Comparable {

    func reload(
        _ tableView: UITableView,
        withData newData: [CellItem],
        groupsAsc: Bool,
        itemsAsc: Bool
    ) {
        assert(tableView.dataSource === self, "Reloading a table view whose data source is not \(self)")

        let configurationFactory: TableDataSourceConfigurationFactory<CellItem> = .grouped(
            .aggregating(
                CellItem.self,
                sortingSection: groupsAsc ? .asc : .desc,
                sortingItems: itemsAsc ? .asc : .desc
            )
        )
        self.dataSourceConfiguration = configurationFactory.produce(newData)
        tableView.reloadData()
    }
}
