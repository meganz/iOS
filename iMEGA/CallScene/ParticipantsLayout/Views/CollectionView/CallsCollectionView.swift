
protocol CallsCollectionViewDelegate: AnyObject {
    func collectionViewDidChangeOffset(to page: Int)
    func collectionViewDidSelectParticipant(participant: CallParticipantEntity, at indexPath: IndexPath)
    func fetchAvatar(for participant: CallParticipantEntity)
}

class CallsCollectionView: UICollectionView {
    private var callParticipants = [CallParticipantEntity]()
    private var layoutMode: CallLayoutMode = .grid
    private weak var callsCollectionViewDelegate: CallsCollectionViewDelegate?
    private var avatars = [UInt64: UIImage]()
    private let spacingForCells: CGFloat = 1.0

    func configure(with callsCollectionViewDelegate: CallsCollectionViewDelegate) {
        dataSource = self
        delegate = self
        self.callsCollectionViewDelegate = callsCollectionViewDelegate
        register(CallParticipantCell.nib, forCellWithReuseIdentifier: CallParticipantCell.reuseIdentifier)
        backgroundColor = .black
    }
    
    func addedParticipant(in participants: [CallParticipantEntity]) {
        callParticipants = participants
        guard participants.count == (numberOfItems(inSection: 0) + 1) else {
            reloadData()
            MEGALogDebug("CallsCollectionView: Add particpant count reload called instead of insert")
            return
        }
        insertItems(at: [IndexPath(item: callParticipants.count - 1, section: 0)])
    }
    
    func deletedParticipant(in participants: [CallParticipantEntity], at index: Int) {
        let cell = cellForItem(at: IndexPath(item: index, section: 0)) as? CallParticipantCell
        cell?.videoImageView.image = nil
        callParticipants = participants
        deleteItems(at: [IndexPath(item: index, section: 0)])
    }
    
    func updateParticipant(in participants: [CallParticipantEntity], at index: Int) {
        callParticipants = participants
        reloadItems(at: [IndexPath(item: index, section: 0)])
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
    
    func changeLayoutMode(_ mode: CallLayoutMode) {
        layoutMode = mode
        reloadData()
        layoutIfNeeded()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        callsCollectionViewDelegate?.collectionViewDidChangeOffset(to: Int(ceil(scrollView.contentOffset.x / scrollView.frame.width)))
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

extension CallsCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return callParticipants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CallParticipantCell", for: indexPath) as? CallParticipantCell else {
            fatalError("Error dequeueReusableCell CallParticipantCell")
        }
        
        let participant = callParticipants[indexPath.item]
        callsCollectionViewDelegate?.fetchAvatar(for: participant)
        cell.configure(for: participant, in: layoutMode)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? CallParticipantCell, let participant = cell.participant, let image = avatars[participant.participantId] else { return }
        cell.setAvatar(image: image)
    }
}

extension CallsCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard layoutMode == .speaker, let selectedParticipant = callParticipants[safe: indexPath.item] else {
            return
        }
        callsCollectionViewDelegate?.collectionViewDidSelectParticipant(participant:selectedParticipant, at: indexPath)
    }
}

extension CallsCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch layoutMode {
        case .grid:
            if UIDevice.current.orientation.isPortrait || UIDevice.current.orientation.isFlat {
                switch callParticipants.count {
                case 1:
                    return collectionView.frame.size
                case 2:
                    return  CGSize(width: collectionView.frame.size.width, height: (collectionView.frame.size.height - spacingForCells) / 2 )
                case 3:
                    return  CGSize(width: collectionView.frame.size.width, height: (collectionView.frame.size.height - spacingForCells * 2) / 3)
                case 4:
                    return  CGSize(width: (collectionView.frame.size.width - spacingForCells) / 2, height: (collectionView.frame.size.height - spacingForCells) / 2)
                default:
                    return  CGSize(width: (collectionView.frame.size.width - spacingForCells) / 2, height: (collectionView.frame.size.height - spacingForCells * 2) / 3)
                }
            } else {
                switch callParticipants.count {
                case 1:
                    return collectionView.frame.size
                case 2:
                    return  CGSize(width: (collectionView.frame.size.width - spacingForCells) / 2, height: collectionView.frame.size.height)
                case 3:
                    return  CGSize(width: (collectionView.frame.size.width - spacingForCells * 2) / 3, height: collectionView.frame.size.height)
                case 4:
                    return  CGSize(width: (collectionView.frame.size.width - spacingForCells) / 2, height: (collectionView.frame.size.height - spacingForCells) / 2)
                default:
                    return  CGSize(width: (collectionView.frame.size.width - spacingForCells * 2) / 3, height: (collectionView.frame.size.height - spacingForCells) / 2)
                }
            }
        case .speaker:
            return  CGSize(width: 100, height: 100)
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
