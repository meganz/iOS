
extension NodeCollectionViewCell {
    class var instantiateFromFileNib: Self {
        guard let cell =  Bundle(for: Self.self)
            .loadNibNamed("FileNodeCollectionViewCell", owner: nil, options: nil)?.first as? Self else {
                fatalError("could not load the instance from nib")
        }
        
        return cell
    }
    
    class var instantiateFromFolderNib: Self {
        guard let cell =  Bundle(for: Self.self)
            .loadNibNamed("FolderNodeCollectionViewCell", owner: nil, options: nil)?.first as? Self else {
                fatalError("could not load the instance from nib")
        }
        
        return cell
    }
}
