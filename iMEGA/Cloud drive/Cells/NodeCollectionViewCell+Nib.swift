extension NodeCollectionViewCell {
    
    private static let nibName: String = "NodeCollectionViewCell"

    static let reusableIdentifier = "NodeCollectionViewID"

    static var cellNib: UINib {
        UINib(nibName: nibName, bundle: nil)
    }
    
    class var instantiateFromNib: Self {
        guard let cell = Bundle(for: Self.self)
            .loadNibNamed(nibName, owner: nil, options: nil)?.first as? Self else {
                fatalError("could not load the instance from nib")
        }
        
        return cell
    }
}
