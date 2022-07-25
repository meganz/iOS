
extension NodeCollectionViewCell {
    
    private static let fileNibName: String = "FileNodeCollectionViewCell"
    
    private static let folderNibName: String = "FolderNodeCollectionViewCell"
    
    static let fileReuseIdentifier: String = "NodeCollectionFileID"
    
    static var fileNib: UINib {
        UINib(nibName: fileNibName, bundle: nil)
    }
    
    class var instantiateFromFileNib: Self {
        guard let cell = Bundle(for: Self.self)
            .loadNibNamed(fileNibName, owner: nil, options: nil)?.first as? Self else {
                fatalError("could not load the instance from nib")
        }
        
        return cell
    }
    
    class var instantiateFromFolderNib: Self {
        guard let cell = Bundle(for: Self.self)
            .loadNibNamed(folderNibName, owner: nil, options: nil)?.first as? Self else {
                fatalError("could not load the instance from nib")
        }
        
        return cell
    }
}
