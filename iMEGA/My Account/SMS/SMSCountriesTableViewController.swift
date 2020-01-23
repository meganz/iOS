
import UIKit

protocol SMSCountriesTableViewControllerDelegate: AnyObject {
    func countriesTableViewController(_ controller: SMSCountriesTableViewController, didSelectCountry country:SMSCountry)
}

class SMSCountriesTableViewController: UITableViewController {
    
    private let countryCellReuseId = "countryCell"
    
    private var countryCallingCodeDict: [String: MEGAStringList]
    private var collation = UILocalizedIndexedCollation.current()
    
    private lazy var countrySections = buildCountrySections()
    
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
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SMSCountriesTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return collation.sectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countrySections[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: countryCellReuseId, for: indexPath)
        let country = countrySections[indexPath.section][indexPath.row]
        cell.textLabel?.text = country.displayName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return collation.sectionTitles[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return collation.section(forSectionIndexTitle: index)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.countriesTableViewController(self, didSelectCountry: countrySections[indexPath.section][indexPath.row])
    }
}
