import ContentLibraries
import MEGADesignToken
import MEGADomain
import SwiftUI
import UIKit

enum VisualMediaSearchResultSupplementaryElementKind: String {
    case titleSectionHeader = "visual-media-search-result-title-section-header-kind"
    var elementKind: String { rawValue }
}

@MainActor
final class VisualMediaSearchResultFoundCollectionViewCoordinator: NSObject {
    typealias DiffableDataSource = UICollectionViewDiffableDataSource<VisualMediaSearchResults.Section, VisualMediaSearchResults.Item>
    private typealias HeaderRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>
    typealias AlbumCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AlbumCellViewModel>
    typealias PhotoCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, PhotoSearchResultItemViewModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<VisualMediaSearchResults.Section, VisualMediaSearchResults.Item>
    
    private let representer: VisualMediaSearchResultFoundView
    private(set) var dataSource: DiffableDataSource?
    private var reloadSnapshotTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    init(_ representer: VisualMediaSearchResultFoundView) {
        self.representer = representer
        super.init()
    }
    
    deinit {
        reloadSnapshotTask?.cancel()
    }
    
    func configureDataSource(for collectionView: UICollectionView) {
        let albumCellRegistration = AlbumCellRegistration { [weak self] cell, _, viewModel in
            self?.configure(cell) {
                AlbumCell(viewModel: viewModel)
                    .background(TokenColors.Background.page.swiftUI)
            }
        }
        let photoCellRegistration = PhotoCellRegistration { [weak self] cell, _, viewModel in
            self?.configure(cell) {
                PhotoSearchResultItemView(viewModel: viewModel)
                    .background(TokenColors.Background.page.swiftUI)
            }
        }
        let headerElementKind = VisualMediaSearchResultSupplementaryElementKind.titleSectionHeader.elementKind
        let headerRegistration = HeaderRegistration(elementKind: headerElementKind) { [weak self] header, _, indexPath in
            guard let title = self?.dataSource?.sectionIdentifier(for: indexPath.section)?.title else { return }
            self?.configure(header) {
                VisualMediaSearchResultsHeaderView(text: title)
            }
        }
        
        let dataSource = DiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .album(let albumViewModel):
                collectionView.dequeueConfiguredReusableCell(using: albumCellRegistration, for: indexPath, item: albumViewModel)
            case .photo(let photoSearchResultItemViewModel):
                collectionView.dequeueConfiguredReusableCell(using: photoCellRegistration, for: indexPath, item: photoSearchResultItemViewModel)
            }
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration,
                                                                  for: indexPath)
        }
        self.dataSource = dataSource
        collectionView.dataSource = dataSource
        collectionView.delegate = self
    }
    
    func reloadData(results: VisualMediaSearchResults) {
        reloadSnapshotTask = Task {
            var snapshot = Snapshot()
            
            for sectionContent in results.sectionContents where sectionContent.items.isNotEmpty {
                snapshot.appendSections([sectionContent.section])
                snapshot.appendItems(sectionContent.items, toSection: sectionContent.section)
            }
            
            guard !Task.isCancelled else { return }
            
            await dataSource?.apply(snapshot, animatingDifferences: false)
        }
    }
    
    private func configure(_ cell: UICollectionViewCell, @ViewBuilder content: () -> some View) {
        cell.contentConfiguration = UIHostingConfiguration(content: content)
            .margins(.all, 0)
    }
}

extension VisualMediaSearchResultFoundCollectionViewCoordinator: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dataSource,
              let selectedItem = dataSource.itemIdentifier(for: indexPath) else { return }
        
        let sectionIdentifier = dataSource.sectionIdentifier(for: indexPath.section)
        let otherQueryItems: [VisualMediaSearchResults.Item] = if let sectionIdentifier {
            dataSource.snapshot().itemIdentifiers(inSection: sectionIdentifier)
        } else {
            []
        }
        representer.selectedItem = .init(
            selectedItem: selectedItem,
            otherQueryItems: otherQueryItems)
    }
}
