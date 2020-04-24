
class AddToChatMediaCollectionSource: NSObject {
    let collectionView: UICollectionView
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        
        super.init()
        
        collectionView.register(AddToChatCameraCollectionCell.nib,
                                   forCellWithReuseIdentifier: AddToChatCameraCollectionCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension AddToChatMediaCollectionSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddToChatCameraCollectionCell.reuseIdentifier,
                                                      for: indexPath) as! AddToChatCameraCollectionCell
        return cell
    }
}

extension AddToChatMediaCollectionSource: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard let cameraCell = cell as? AddToChatCameraCollectionCell else {
            return
        }
        
        do {
            try cameraCell.showLiveFeed()
        } catch {
            print("camera live feed error \(error.localizedDescription)")
        }
    }
}
