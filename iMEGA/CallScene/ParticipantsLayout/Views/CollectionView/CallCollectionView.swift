import MEGADomain

protocol CallCollectionViewDelegate: AnyObject {
    func collectionViewDidChangeOffset(to page: Int, visibleIndexPaths: [IndexPath])
    func collectionViewDidSelectParticipant(participant: CallParticipantEntity, at indexPath: IndexPath)
    func fetchAvatar(for participant: CallParticipantEntity)
    func participantCellIsVisible(_ participant: CallParticipantEntity, at indexPath: IndexPath)
}

class CallCollectionView: UICollectionView {
    enum SectionType: Hashable {
        case main
    }
    private var callParticipants = [CallParticipantEntity]()
    private var layoutMode: ParticipantsLayoutMode = .grid
    private weak var callCollectionViewDelegate: CallCollectionViewDelegate?
    private var avatars = [UInt64: UIImage]()
    private let spacingForCells: CGFloat = 1.0
    private var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, CallParticipantEntity>?
    
    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.clipsToBounds = true
        return blurEffectView
    }()
    
    func addBlurEffect() {
        addSubview(blurEffectView)
    }
    
    func removeBlurEffect() {
        blurEffectView.removeFromSuperview()
    }
    
    func configure(with callCollectionViewDelegate: CallCollectionViewDelegate) {
        
        diffableDataSource = UICollectionViewDiffableDataSource(
            collectionView: self,
            cellProvider: { [unowned self] collectionView, indexPath, _ in
                // using unowned here since collection view is the owner of the data source
                // so, collection view will be deallocated together with data source, no chance
                // of self being nil here
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CallParticipantCell", for: indexPath) as? CallParticipantCell else {
                    fatalError("Error dequeueReusableCell CallParticipantCell")
                }
                
                let participant = callParticipants[indexPath.item]
                if let image = avatars[participant.participantId] {
                    cell.setAvatar(image: image)
                }
                callCollectionViewDelegate.fetchAvatar(for: participant)
                cell.configure(for: participant, in: layoutMode)
                return cell
            }
        )
        
        dataSource = diffableDataSource
        delegate = self
        self.callCollectionViewDelegate = callCollectionViewDelegate
        register(CallParticipantCell.nib, forCellWithReuseIdentifier: CallParticipantCell.reuseIdentifier)
        backgroundColor = .black
    }
    
    // call this instead of manual calling insert/delete/reload cell
    private func updateCells(with participants: [CallParticipantEntity]) {
        
        callParticipants = participants
        // code below does inserts and reloads but we do reloads manually to avoid flashing of cells when reconfiguring
        
        var snapshot = NSDiffableDataSourceSnapshot<SectionType, CallParticipantEntity>()
        snapshot.appendSections([SectionType.main])
        snapshot.appendItems(participants, toSection: SectionType.main)
        diffableDataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    func update(participants: [CallParticipantEntity]) {
        updateCells(with: participants)
    }
    
    func reloadParticipant(in participants: [CallParticipantEntity], at index: Int) {
        updateCells(with: participants)
        guard let cell = cellForItem(at: IndexPath(item: index, section: 0)) as? CallParticipantCell, let participant = cell.participant else {
            return
        }
        if visibleCells.contains(cell) {
            cell.configure(for: participant, in: layoutMode)
            callCollectionViewDelegate?.participantCellIsVisible(participant, at: IndexPath(item: index, section: 0))
        }
    }
    
    func updateAvatar(image: UIImage, for participant: CallParticipantEntity) {
        avatars[participant.participantId] = image
        guard let index = callParticipants.firstIndex(where: { $0 == participant }),
              case let indexPath = IndexPath(item: index, section: 0),
              let cell = cellForItem(at: indexPath) as? CallParticipantCell,
              cell.participant == participant else {
                  return
              }
        
        cell.setAvatar(image: image)
    }
    
    func changeLayoutMode(_ mode: ParticipantsLayoutMode) {
        layoutMode = mode
        isPagingEnabled = layoutMode == .grid
        reloadData()
        layoutIfNeeded()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        callCollectionViewDelegate?.collectionViewDidChangeOffset(to: Int(ceil(scrollView.contentOffset.x / scrollView.frame.width)), visibleIndexPaths: indexPathsForVisibleItems)
    }
    
    func configurePinnedCell(at indexPath: IndexPath?) {
        visibleCells.forEach { cell in
            cell.borderWidth = 0
            cell.borderColor = .clear
        }
        
        guard let indexPath = indexPath, let pinnedCell = cellForItem(at: indexPath) else {
            return
        }
        pinnedCell.borderWidth = 1
        pinnedCell.borderColor = .systemYellow
    }
}

extension CallCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard layoutMode == .speaker, let selectedParticipant = callParticipants[safe: indexPath.item] else {
            return
        }
        callCollectionViewDelegate?.collectionViewDidSelectParticipant(participant: selectedParticipant, at: indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let participant = callParticipants[indexPath.item]
        callCollectionViewDelegate?.participantCellIsVisible(participant, at: indexPath)
    }
}

extension CallCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch layoutMode {
        case .grid:
            let width: CGFloat = collectionView.frame.size.width
            let height: CGFloat = collectionView.frame.size.height
            
            if height > width {
                switch callParticipants.count {
                case 1:
                    return collectionView.frame.size
                case 2:
                    return  CGSize(width: width, height: height / 2 - spacingForCells)
                case 3:
                    return  CGSize(width: width, height: height / 3 - spacingForCells)
                case 4:
                    return  CGSize(width: width / 2  - spacingForCells, height: height / 2 - spacingForCells)
                default:
                    return  CGSize(width: width / 2 - spacingForCells, height: height / 3 - spacingForCells)
                }
            } else {
                switch callParticipants.count {
                case 1:
                    return collectionView.frame.size
                case 2:
                    return  CGSize(width: width / 2 - spacingForCells, height: height)
                case 3:
                    return  CGSize(width: width / 3 - spacingForCells, height: height)
                case 4:
                    return  CGSize(width: width / 2 - spacingForCells, height: height / 2 - spacingForCells)
                default:
                    return  CGSize(width: width / 3 - spacingForCells, height: height / 2 - spacingForCells)
                }
            }
        case .speaker:
            let length: CGFloat = 100
            return  CGSize(width: length, height: length)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch layoutMode {
        case .grid:
            return 1.0
        case .speaker:
            return 4.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch layoutMode {
        case .grid:
            return .zero
        case .speaker:
            return UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        }
    }
}
