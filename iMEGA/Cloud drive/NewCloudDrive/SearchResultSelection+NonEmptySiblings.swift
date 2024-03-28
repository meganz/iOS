import Search

extension SearchResultSelection {
    func nonEmptyOrNilSiblingsIds() -> [ResultId]? {
        let siblings = self.siblings()
        guard siblings.isNotEmpty else {
            return nil
        }
        return siblings
    }
}
