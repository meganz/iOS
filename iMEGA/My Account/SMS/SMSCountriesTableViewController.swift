
import UIKit

protocol SMSCountriesTableViewControllerDelegate: AnyObject {
    func countriesTableViewController(_ controller: SMSCountriesTableViewController?, didSelectCountry country:SMSCountry)
}

class SMSCountriesTableViewController: UITableViewController {
    
    private var searchController = UISearchController(searchResultsController: nil)

    private let countryCellReuseId = "countryCell"
    
    private var countryCallingCodeDict: [String: MEGAStringList]
    private var collation = UILocalizedIndexedCollation.current()
    
    private lazy var countrySections = buildCountrySections()
    private lazy var filteredCountries: [SMSCountry] = []

    private weak var delegate: SMSCountriesTableViewControllerDelegate?
    
    init(countryCallingCodeDict: [String: MEGAStringList], delegate: SMSCountriesTableViewControllerDelegate? = nil) {
        self.countryCallingCodeDict = countryCallingCodeDict
        self.delegate = delegate
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = AMLocalizedString("Choose Your Country")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: countryCellReuseId)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.backgroundColor = .clear
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
            searchController.searchBar.barTintColor = .white
            tableView.contentOffset = CGPoint(x: 0, y: searchController.searchBar.frame.height)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    private func buildCountrySections() -> [[SMSCountry]] {
        guard let appLanguageId = LocalizationSystem.sharedLocal()?.getLanguage() else {
            return []
        }
        
        let appLocale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.languageCode.rawValue : appLanguageId]))
        let allCountries = countryCallingCodeDict.compactMap {
            SMSCountry(countryCode: $0.key, countryLocalizedName: appLocale.localizedString(forRegionCode: $0.key), callingCode: $0.value.string(at: 0))
        }
        
        var sections = collation.sectionTitles.map { _ in [SMSCountry]() }
        for country in allCountries {
            let sectionIndex = collation.section(for: country, collationStringSelector: #selector(getter: SMSCountry.countryLocalizedName))
            sections[sectionIndex].append(country)
        }
        
        return sections.compactMap {
            collation.sortedArray(from: $0, collationStringSelector: #selector(getter: SMSCountry.countryLocalizedName)) as? [SMSCountry]
        }
    }
    
    func smsCountry(for indexPath: IndexPath) -> SMSCountry {
        isSearching ? filteredCountries[indexPath.row] : countrySections[indexPath.section][indexPath.row]
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SMSCountriesTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : collation.sectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredCountries.count : countrySections[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: countryCellReuseId, for: indexPath)
        let country = smsCountry(for: indexPath)
        cell.textLabel?.text = country.displayName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isSearching ? nil : collation.sectionTitles[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return isSearching ? nil : collation.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return collation.section(forSectionIndexTitle: index)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = smsCountry(for: indexPath)
        if #available(iOS 13.0, *) {
            searchController.dismiss(animated: true) { [weak self] in
                self?.delegate?.countriesTableViewController(self, didSelectCountry: country)
            }
        } else {
            searchController.isActive = false
            delegate?.countriesTableViewController(self, didSelectCountry: country)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension SMSCountriesTableViewController: UISearchResultsUpdating {

    var isSearching: Bool {
        searchController.isActive && !isSearchBarEmpty
    }

    var isSearchBarEmpty: Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }

    public func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        filteredCountries = countrySections.joined().filter({ country in
            country.displayName.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
}
