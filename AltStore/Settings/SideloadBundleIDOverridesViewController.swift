//
//  SideloadBundleIDOverridesViewController.swift
//

import UIKit
import AltStoreCore

/// Edit preset bundle IDs keyed by an app’s **source** bundle identifier (shown before install).
final class SideloadBundleIDOverridesViewController: UITableViewController {

    private var pairs: [(source: String, override: String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Bundle ID presets", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPreset)
        )

        reloadPairs()
    }

    private func reloadPairs() {
        let dict = UserDefaults.standard.sideloadBundleIdentifierOverrides
        pairs = dict.keys.sorted().map { ($0, dict[$0] ?? "") }
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        default: return pairs.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("About", comment: "")
        default:
            return NSLocalizedString("Presets", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "about") ?? UITableViewCell(style: .default, reuseIdentifier: "about")
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.textColor = .label
            cell.textLabel?.font = .preferredFont(forTextStyle: .footnote)
            cell.textLabel?.text = NSLocalizedString(
                "Turn on “Customize installed app bundle identifier” in Advanced Settings. Add rows here to skip the prompt: use each app’s catalog bundle ID as the key, and the full bundle ID you want when sideloading (often ending with your team ID).",
                comment: ""
            )
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "preset") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "preset")
            cell.selectionStyle = .default
            cell.backgroundColor = .clear
            let row = pairs[indexPath.row]
            cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            cell.textLabel?.textColor = .label
            cell.detailTextLabel?.font = .preferredFont(forTextStyle: .caption1)
            cell.detailTextLabel?.textColor = UIColor.fluxSecondaryText
            cell.textLabel?.text = row.source
            cell.detailTextLabel?.text = row.override
            cell.accessoryType = .none
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 1
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, indexPath.section == 1 else { return }
        let source = pairs[indexPath.row].source
        var dict = UserDefaults.standard.sideloadBundleIdentifierOverrides
        dict.removeValue(forKey: source)
        UserDefaults.standard.sideloadBundleIdentifierOverrides = dict
        reloadPairs()
    }

    @objc private func addPreset() {
        let alert = UIAlertController(
            title: NSLocalizedString("Add preset", comment: ""),
            message: NSLocalizedString("Source bundle ID is the ID from the catalog. Override is the full bundle ID used when signing.", comment: ""),
            preferredStyle: .alert
        )

        alert.addTextField { $0.placeholder = NSLocalizedString("Source bundle ID", comment: ""); $0.autocapitalizationType = .none }
        alert.addTextField { $0.placeholder = NSLocalizedString("Override bundle ID", comment: ""); $0.autocapitalizationType = .none }

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default) { [weak self] _ in
            guard let self else { return }
            let src = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let ovr = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard Self.isValidBundleID(src), Self.isValidBundleID(ovr) else {
                let err = UIAlertController(
                    title: NSLocalizedString("Invalid bundle ID", comment: ""),
                    message: NSLocalizedString("Use reverse-DNS form like com.example.app.teamID.", comment: ""),
                    preferredStyle: .alert
                )
                err.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                self.present(err, animated: true)
                return
            }
            var dict = UserDefaults.standard.sideloadBundleIdentifierOverrides
            dict[src] = ovr
            UserDefaults.standard.sideloadBundleIdentifierOverrides = dict
            self.reloadPairs()
        })

        present(alert, animated: true)
    }

    private static func isValidBundleID(_ value: String) -> Bool {
        let pattern = #"^[A-Za-z][A-Za-z0-9\-]*(\.[A-Za-z0-9\-]+)+$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
