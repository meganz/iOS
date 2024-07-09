import MEGADesignToken
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
    var layoutMode: ParticipantsLayoutMode = .grid
    private weak var callCollectionViewDelegate: (any CallCollectionViewDelegate)?
    private var avatars = [UInt64: UIImage]()
    private let spacingForCells: CGFloat = 2.0
    private var diffableDataSource: UICollectionViewDiffableDataSource<SectionType, CallParticipantEntity>?
    
    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.clipsToBounds = true
        return blurEffectView
    }()
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBlurViewBounds()
    }
    
    func addBlurEffect() {
        updateBlurViewBounds()
        addSubview(blurEffectView)
    }
    
    func removeBlurEffect() {
        blurEffectView.removeFromSuperview()
    }
    
    func configure(with callCollectionViewDelegate: some CallCollectionViewDelegate) {
        diffableDataSource = UICollectionViewDiffableDataSource(
            collectionView: self,
            cellProvider: { [unowned self, weak callCollectionViewDelegate] collectionView, indexPath, _ in
                // using unowned here since collection view is the owner of the data source
                // so, collection view will be deallocated together with data source, no chance
                // of self being nil here
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CallParticipantCell", for: indexPath) as? CallParticipantCell else {
                    fatalError("Error dequeueReusableCell CallParticipantCell")
                }
                
                let participant = callParticipants[indexPath.item]
                if let image = avatars[participant.participantId], !participant.isScreenShareCell {
                    cell.setAvatar(image: image)
                }
                if !participant.isScreenShareCell {
                    callCollectionViewDelegate?.fetchAvatar(for: participant)
                }
                cell.configure(for: participant, in: layoutMode)
                return cell
            }
        )
        
        dataSource = diffableDataSource
        delegate = self
        self.callCollectionViewDelegate = callCollectionViewDelegate
        register(CallParticipantCell.nib, forCellWithReuseIdentifier: CallParticipantCell.reuseIdentifier)
        backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.black000000
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
        cell.configure(for: participant, in: layoutMode)
        if visibleCells.contains(cell) {
            callCollectionViewDelegate?.participantCellIsVisible(participant, at: IndexPath(item: index, section: 0))
        }
    }
    
    func updateAvatar(image: UIImage, for participant: CallParticipantEntity) {
        avatars[participant.participantId] = image
        guard let index = callParticipants.firstIndex(where: { $0 == participant && !$0.isScreenShareCell }),
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
    
    private func updateBlurViewBounds() {
        blurEffectView.frame = bounds
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
            return 4.0
        case .speaker:
            return 4.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
