
protocol CallsCollectionViewScrollDelegate: AnyObject {
    func collectionViewDidChangeOffset(to page: Int)
}

class CallsCollectionView: UICollectionView {
    private var callParticipants = [CallParticipantEntity]()
    private var layoutMode: CallLayoutMode = .grid
    private weak var scrollDelegate: CallsCollectionViewScrollDelegate?

    private let spacingForCells: CGFloat = 1.0

    func configure(with scrollDelegate: CallsCollectionViewScrollDelegate) {
        dataSource = self
        delegate = self
        self.scrollDelegate = scrollDelegate
        register(CallParticipantCell.nib, forCellWithReuseIdentifier: CallParticipantCell.reuseIdentifier)
    }
    
    func addedParticipant(in participants: [CallParticipantEntity]) {
        callParticipants = participants
        insertItems(at: [IndexPath(item: callParticipants.count - 1, section: 0)])
    }
    
    func deletedParticipant(in participants: [CallParticipantEntity], at index: Int) {
        callParticipants = participants
        deleteItems(at: [IndexPath(item: index, section: 0)])
    }
    
    func updateParticipant(in participants: [CallParticipantEntity], at index: Int) {
        callParticipants = participants
        reloadItems(at: [IndexPath(item: index, section: 0)])
    }
    
    func changeLayoutMode(_ mode: CallLayoutMode) {
        layoutMode = mode
        reloadData()
        layoutIfNeeded()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollDelegate?.collectionViewDidChangeOffset(to: Int(ceil(scrollView.contentOffset.x / scrollView.frame.width)))
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
        cell.configure(for: callParticipants[indexPath.item], in: layoutMode)
        return cell
    }
}

extension CallsCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch layoutMode {
        case .grid:
            if UIDevice.current.orientation.isPortrait {
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
