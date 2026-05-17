//
//  FluxNotificationCenterViewController.swift
//  aerostore
//
//  Created by aerostore Team
//  Copyright © 2026 aerostore. All rights reserved.
//

import UIKit
import AltStoreCore

class FluxNotificationCenterViewController: UIViewController {
    private let tableView = UITableView()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateImageView = UIImageView()
    
    private var notifications: [FluxNotification] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupTableView()
        setupEmptyState()
        loadNotifications()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("Notifications", comment: "")
        
        // Modern rounded corners for the main view
        view.layer.cornerRadius = 0
        view.layer.cornerCurve = .continuous
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Add clear all button
        let clearButton = UIBarButtonItem(
            title: NSLocalizedString("Clear All", comment: ""),
            style: .plain,
            target: self,
            action: #selector(clearAllNotifications)
        )
        navigationItem.rightBarButtonItem = clearButton
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        // Modern cell registration
        tableView.register(FluxNotificationTableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateImageView.image = UIImage(systemName: "bell.slash")
        emptyStateImageView.tintColor = .secondaryLabel
        emptyStateImageView.contentMode = .scaleAspectFit
        
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = NSLocalizedString("No notifications", comment: "")
        emptyStateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 64),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 64),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func loadNotifications() {
        // Load notifications from storage or show sample notifications
        notifications = [
            FluxNotification(
                id: "sample_1",
                title: NSLocalizedString("App Update Available", comment: ""),
                body: "FluxDebug has an update available",
                category: .appUpdate,
                userInfo: ["bundleIdentifier": "com.flux.fluxdebug"]
            ),
            FluxNotification(
                id: "sample_2",
                title: NSLocalizedString("JIT Status Changed", comment: ""),
                body: "JIT for Safari has been enabled",
                category: .jitStatus,
                userInfo: ["appName": "Safari", "enabled": true]
            )
        ]
        
        updateEmptyState()
        tableView.reloadData()
    }
    
    private func updateEmptyState() {
        emptyStateView.isHidden = !notifications.isEmpty
        tableView.isHidden = notifications.isEmpty
    }
    
    @objc private func clearAllNotifications() {
        notifications.removeAll()
        updateEmptyState()
        tableView.reloadData()
        
        // Show toast confirmation
        let toastView = ToastView(text: NSLocalizedString("All notifications cleared", comment: ""), detailText: nil)
        if let tabBarController = tabBarController {
            toastView.show(in: tabBarController)
        }
    }
}

// MARK: - UITableViewDataSource
extension FluxNotificationCenterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! FluxNotificationTableViewCell
        cell.configure(with: notifications[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FluxNotificationCenterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let notification = notifications[indexPath.row]
        handleNotificationTap(notification)
        
        // Remove notification after tapping
        notifications.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        updateEmptyState()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [weak self] _, _, completion in
            self?.notifications.remove(at: indexPath.row)
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            self?.updateEmptyState()
            completion(true)
        }
        
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func handleNotificationTap(_ notification: FluxNotification) {
        switch notification.category {
        case .appUpdate:
            if let bundleIdentifier = notification.userInfo["bundleIdentifier"] as? String {
                navigateToApp(bundleIdentifier: bundleIdentifier)
            }
        case .refreshReminder:
            if let appName = notification.userInfo["appName"] as? String {
                navigateToApp(appName: appName)
            }
        case .certificateWarning:
            navigateToSettings()
        case .jitStatus:
            if let appName = notification.userInfo["appName"] as? String {
                navigateToApp(appName: appName)
            }
        case .system:
            break
        case .general:
            break
        }
    }
    
    private func navigateToApp(bundleIdentifier: String) {
        if let tabBarController = tabBarController {
            tabBarController.selectedIndex = TabBarController.Tab.myApps.rawValue
            NotificationCenter.default.post(name: NSNotification.Name("ShowAppDetails"), object: nil, userInfo: ["bundleIdentifier": bundleIdentifier])
        }
    }
    
    private func navigateToApp(appName: String) {
        if let tabBarController = tabBarController {
            tabBarController.selectedIndex = TabBarController.Tab.myApps.rawValue
            NotificationCenter.default.post(name: NSNotification.Name("ShowAppDetails"), object: nil, userInfo: ["appName": appName])
        }
    }
    
    private func navigateToSettings() {
        if let tabBarController = tabBarController {
            tabBarController.selectedIndex = TabBarController.Tab.settings.rawValue
        }
    }
}

// MARK: - Modern Notification Cell
class FluxNotificationTableViewCell: UITableViewCell {
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Container setup
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.cornerCurve = .continuous
        
        // Icon setup
        containerView.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .fluxPrimary
        
        // Title setup
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        
        // Message setup
        containerView.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 2
        
        // Time setup
        containerView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.numberOfLines = 1
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(equalToConstant: 60),
            timeLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with notification: FluxNotification) {
        titleLabel.text = notification.title
        messageLabel.text = notification.body
        timeLabel.text = "now"
        
        switch notification.category {
        case .appUpdate:
            iconImageView.image = UIImage(systemName: "arrow.down.circle.fill")
        case .refreshReminder:
            iconImageView.image = UIImage(systemName: "clock.fill")
        case .certificateWarning:
            iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        case .jitStatus:
            iconImageView.image = UIImage(systemName: "bolt.circle.fill")
        case .system:
            iconImageView.image = UIImage(systemName: "info.circle.fill")
        case .general:
            iconImageView.image = UIImage(systemName: "bell.fill")
        }
    }
}
