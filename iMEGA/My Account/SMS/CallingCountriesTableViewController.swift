
import UIKit

class CallingCountriesTableViewController: UITableViewController {
    
    private let countryCellReuseId = "countryCell"
    
    private var countryCallingCodeDict: [String: MEGAStringList]
    private var collation = UILocalizedIndexedCollation.current()
    
    private lazy var countrySections = self.buildCountrySections()
    
    init(countryCallingCodeDict: [String: MEGAStringList]) {
        self.countryCallingCodeDict = countryCallingCodeDict
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Choose Your Country"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: countryCellReuseId)
    }
    
    private func buildCountrySections() -> [[CallingCountry]] {
        guard let appLanguageId = LocalizationSystem.sharedLocal()?.getLanguage() else {
            return []
        }
        
        let appLocale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.languageCode.rawValue : appLanguageId]))
        let allCountries = countryCallingCodeDict.map {
            CallingCountry(countryCode: $0.key, countryLocalizedName: appLocale.localizedString(forRegionCode: $0.key), callingCode: $0.value.first)
            }.compactMap { $0 }
        
        var sections = collation.sectionTitles.map { _ in [CallingCountry]() }
        for country in allCountries {
            let sectionIndex = collation.section(for: country, collationStringSelector: #selector(getter: CallingCountry.countryLocalizedName))
            sections[sectionIndex].append(country)
        }
        
        return sections.map {
            collation.sortedArray(from: $0, collationStringSelector: #selector(getter: CallingCountry.countryLocalizedName)) as? [CallingCountry]
            }.compactMap { $0 }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension CallingCountriesTableViewController {
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
}
