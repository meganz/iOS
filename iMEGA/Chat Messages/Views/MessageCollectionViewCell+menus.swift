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
    
    @objc func edit(_ sender: Any?) {
        
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                // Trigger action
                collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.edit(_:)), forItemAt: indexPath, withSender: sender)
            }
        }
        
    
    }
    
    @objc open override func delete(_ sender: Any?) {
        // Get the collectionView
          if let collectionView = self.superview as? UICollectionView {
              // Get indexPath
              if let indexPath = collectionView.indexPath(for: self) {
                  // Trigger action
                  collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.delete(_:)), forItemAt: indexPath, withSender: sender)
              }
          }
    }
    
    @objc func download(_ sender: Any?) {
        // Get the collectionView
          if let collectionView = self.superview as? UICollectionView {
              // Get indexPath
              if let indexPath = collectionView.indexPath(for: self) {
                  // Trigger action
                  collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.download(_:)), forItemAt: indexPath, withSender: sender)
              }
          }
    }
    
    @objc func removeRichPreview(_ sender: Any?) {
        // Get the collectionView
          if let collectionView = self.superview as? UICollectionView {
              // Get indexPath
              if let indexPath = collectionView.indexPath(for: self) {
                  // Trigger action
                  collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.removeRichPreview(_:)), forItemAt: indexPath, withSender: sender)
              }
          }
    }
    
    @objc func addContact(_ sender: Any?) {
        // Get the collectionView
          if let collectionView = self.superview as? UICollectionView {
              // Get indexPath
              if let indexPath = collectionView.indexPath(for: self) {
                  // Trigger action
                  collectionView.delegate?.collectionView?(collectionView, performAction: #selector(MessageCollectionViewCell.addContact(_:)), forItemAt: indexPath, withSender: sender)
              }
          }
    }

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                // Trigger action
                return (collectionView.delegate?.collectionView?(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender))!
            }
        }
        return false
    }
}
