import MessageKit

extension MessageCollectionViewCell {
    @objc func forward(_ sender: Any?) {
        
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                // Trigger action
                collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.forward(_:)), forItemAt: indexPath, withSender: sender)
            }
        }
    }
    
    @objc func importMessage(_ sender: Any?) {
           
           // Get the collectionView
           if let collectionView = self.superview as? UICollectionView {
               // Get indexPath
               if let indexPath = collectionView.indexPath(for: self) {
                   // Trigger action
                   collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.importMessage(_:)), forItemAt: indexPath, withSender: sender)
               }
           }
       }
}
