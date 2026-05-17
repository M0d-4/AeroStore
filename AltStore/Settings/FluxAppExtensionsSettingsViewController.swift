//
//  FluxAppExtensionsSettingsViewController.swift
//  aerostore
//
//  Created by aerostore Team on 5/12/2024.
//  Copyright © 2024. All rights reserved.
//

import UIKit
import AltStoreCore

class FluxAppExtensionsSettingsViewController: UITableViewController {
    
    private let settings = [
        SettingItem(
            title: NSLocalizedString("Show App Extensions Prompt", comment: ""),
            subtitle: NSLocalizedString("Show prompt when installing apps with extensions", comment: ""),
            key: "aerostore.showAppExtensionsPrompt",
            type: .toggle,
            defaultValue: true
        ),
        SettingItem(
            title: NSLocalizedString("Keep App Extensions by Default", comment: ""),
            subtitle: NSLocalizedString("Automatically keep app extensions when prompted", comment: ""),
            key: "aerostore.keepAppExtensionsByDefault",
            type: .toggle,
            defaultValue: false
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("App Extensions", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.register(SettingsToggleCell.self, forCellReuseIdentifier: "ToggleCell")
        tableView.register(SettingsInfoCell.self, forCellReuseIdentifier: "InfoCell")
    }
}

// MARK: - UITableViewDataSource

extension FluxAppExtensionsSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return settings.count
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let setting = settings[indexPath.row]
            
            switch setting.type {
            case .toggle:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath) as! SettingsToggleCell
                cell.configure(with: setting)
                cell.delegate = self
                return cell
            default:
                return UITableViewCell()
            }
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell", for: indexPath) as! SettingsInfoCell
            cell.configure(
                title: NSLocalizedString("About App Extensions", comment: ""),
                message: NSLocalizedString("App extensions provide additional functionality but may require additional permissions. You can control how aerostore handles app extensions here.", comment: "")
            )
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("Extension Settings", comment: "")
        case 1:
            return NSLocalizedString("Information", comment: "")
        default:
            return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension FluxAppExtensionsSettingsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            showAppExtensionsInfo()
        }
    }
    
    private func showAppExtensionsInfo() {
        let alert = UIAlertController(
            title: NSLocalizedString("App Extensions", comment: ""),
            message: NSLocalizedString("App extensions are small programs that extend the functionality of your apps. They can provide features like:\n\n• Share sheets\n• Widgets\n• Custom keyboards\n• Photo editing tools\n\naerostore can automatically handle these extensions or prompt you for each installation.", comment: ""),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SettingsToggleCellDelegate

extension FluxAppExtensionsSettingsViewController: SettingsToggleCellDelegate {
    func settingsToggleCell(_ cell: SettingsToggleCell, didChangeValue value: Bool, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
        
        // Special handling for app extensions prompt
        if key == "aerostore.showAppExtensionsPrompt" {
            NotificationCenter.default.post(name: .fluxAppExtensionsSettingsChanged, object: nil)
        }
    }
}

// MARK: - Data Models

struct SettingItem {
    let title: String
    let subtitle: String
    let key: String
    let type: SettingType
    let defaultValue: Any
    
    enum SettingType {
        case toggle
        case selection
        case info
    }
}

// MARK: - Custom Cells

class SettingsToggleCell: UITableViewCell {
    
    var delegate: SettingsToggleCellDelegate?
    private var settingKey: String = ""
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .fluxSecondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .fluxCardBackground
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(toggleSwitch)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: toggleSwitch.leadingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: toggleSwitch.leadingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            toggleSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    func configure(with setting: SettingItem) {
        titleLabel.text = setting.title
        subtitleLabel.text = setting.subtitle
        settingKey = setting.key
        
        let currentValue = UserDefaults.standard.object(forKey: setting.key) as? Bool ?? setting.defaultValue as? Bool ?? false
        toggleSwitch.isOn = currentValue
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        delegate?.settingsToggleCell(self, didChangeValue: sender.isOn, for: settingKey)
    }
}

protocol SettingsToggleCellDelegate: AnyObject {
    func settingsToggleCell(_ cell: SettingsToggleCell, didChangeValue value: Bool, for key: String)
}

class SettingsInfoCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .altPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .fluxSecondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .fluxCardBackground
        selectionStyle = .default
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(title: String, message: String) {
        titleLabel.text = title
        messageLabel.text = message
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let fluxAppExtensionsSettingsChanged = Notification.Name("FluxAppExtensionsSettingsChanged")
}
