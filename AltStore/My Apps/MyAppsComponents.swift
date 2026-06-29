//
//  MyAppsComponents.swift
//  AltStore
//
//  Created by Riley Testut on 7/17/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import Roxas
import AltStoreCore
import Nuke

final class InstalledAppCollectionViewCell: UICollectionViewCell
{
    private(set) var deactivateBadge: UIView?
    
    @IBOutlet var bannerView: AppBannerView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.preservesSuperviewLayoutMargins = true
        self.contentView.backgroundColor = UIColor.fluxCardBackground
        self.contentView.layer.cornerRadius = 20
        self.contentView.layer.cornerCurve = .continuous
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor.fluxCardBorder.cgColor
        self.contentView.layer.masksToBounds = true

        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.07
        self.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.layer.shadowRadius = 10
        
        let deactivateBadge = UIView()
        deactivateBadge.translatesAutoresizingMaskIntoConstraints = false
        deactivateBadge.isHidden = true
        self.addSubview(deactivateBadge)
        
        // Solid background to make the X opaque white.
        let backgroundView = UIView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .white
        deactivateBadge.addSubview(backgroundView)
                    
        let badgeView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
        badgeView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
        badgeView.tintColor = .systemRed
        deactivateBadge.addSubview(badgeView, pinningEdgesWith: .zero)
        
        NSLayoutConstraint.activate([
            deactivateBadge.centerXAnchor.constraint(equalTo: self.bannerView.iconImageView.trailingAnchor),
            deactivateBadge.centerYAnchor.constraint(equalTo: self.bannerView.iconImageView.topAnchor),
            
            backgroundView.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            backgroundView.widthAnchor.constraint(equalTo: badgeView.widthAnchor, multiplier: 0.5),
            backgroundView.heightAnchor.constraint(equalTo: badgeView.heightAnchor, multiplier: 0.5)
        ])
        
        self.deactivateBadge = deactivateBadge
    }

    override func layoutSubviews()
    {
        super.layoutSubviews()
        self.layer.shadowPath = UIBezierPath(roundedRect: self.contentView.frame, cornerRadius: self.contentView.layer.cornerRadius).cgPath
    }
}

final class InstalledAppsCollectionFooterView: UICollectionReusableView
{
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var button: UIButton!
}

final class NoUpdatesCollectionViewCell: UICollectionViewCell
{
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var button: UIButton!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.contentView.preservesSuperviewLayoutMargins = true
        self.contentView.layer.cornerRadius = 20
        self.contentView.layer.cornerCurve = .continuous
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor.fluxCardBorder.cgColor
        self.blurView.layer.cornerRadius = 20
        self.blurView.clipsToBounds = true
        
        let font = self.textLabel.font ?? UIFont.systemFont(ofSize: 17)
        let configuration = UIImage.SymbolConfiguration(font: font)
        let image = UIImage(systemName: "ellipsis.circle", withConfiguration: configuration)
        
        self.button.setTitle("", for: .normal)
        self.button.setImage(image, for: .normal)
    }
}

final class AeroStoreSelfUpdateCell: UICollectionViewCell
{
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var cachedVersionString: String = ""

    override init(frame: CGRect)
    {
        super.init(frame: frame)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .fluxCardBackground
        cardView.layer.cornerRadius = 20
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.fluxCardBorder.cgColor

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "arrow.down.circle.fill")
        iconView.tintColor = .altPrimary
        iconView.contentMode = .scaleAspectFit

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.tintColor = .altPrimary

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .fluxSecondaryText
        subtitleLabel.numberOfLines = 2

        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(activityIndicator)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            activityIndicator.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
        ])

        contentView.preservesSuperviewLayoutMargins = true
    }

    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with info: AeroStoreGitHubRelease.UpdateInfo)
    {
        cachedVersionString = info.versionString
        titleLabel.text = String(format: NSLocalizedString("aerostore %@ is available", comment: ""), info.versionString)
        subtitleLabel.text = NSLocalizedString("Tap to download and install", comment: "")
        setDownloading(false)
    }

    func setDownloading(_ isDownloading: Bool)
    {
        isUserInteractionEnabled = !isDownloading
        if isDownloading
        {
            activityIndicator.startAnimating()
            iconView.isHidden = true
            titleLabel.text = String(format: NSLocalizedString("aerostore %@ is available", comment: ""), cachedVersionString)
            subtitleLabel.text = NSLocalizedString("Downloading…", comment: "")
        }
        else
        {
            activityIndicator.stopAnimating()
            iconView.isHidden = false
            subtitleLabel.text = NSLocalizedString("Tap to download and install", comment: "")
        }
    }
}

final class UpdatesCollectionHeaderView: UICollectionReusableView
{
    let button = PillButton(type: .system)
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.setTitle(">", for: .normal)
        self.addSubview(self.button)
        
        NSLayoutConstraint.activate([self.button.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
                                     self.button.topAnchor.constraint(equalTo: self.topAnchor),
                                     self.button.widthAnchor.constraint(equalToConstant: 50),
                                     self.button.heightAnchor.constraint(equalToConstant: 26)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Flux App Data & Save State Manager
final class FluxAppDataManagerViewController: UIViewController {
    private let installedApp: InstalledApp
    private weak var myAppsViewController: MyAppsViewController?
    
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    
    private let lastModifiedLabel = UILabel()
    private let sizeLabel = UILabel()
    private let statusBadgeLabel = UILabel()
    
    private var restoreButton: UIButton!
    private var exportButton: UIButton!
    private var rollbackButton: UIButton!
    private var rollbackCard: UIView!
    
    init(installedApp: InstalledApp, myAppsViewController: MyAppsViewController) {
        self.installedApp = installedApp
        self.myAppsViewController = myAppsViewController
        super.init(nibName: nil, bundle: nil)
        self.title = NSLocalizedString("Save States & Data", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        
        setupUI()
        refreshData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDataDidChange), name: NSNotification.Name("FluxAppDataDidChange"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDataDidChange), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true)
    }
    
    @objc private func appDataDidChange() {
        DispatchQueue.main.async {
            self.refreshData()
        }
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        // 1. App Header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 16
        headerStack.alignment = .center
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 14
        iconImageView.layer.cornerCurve = .continuous
        iconImageView.clipsToBounds = true
        iconImageView.layer.borderWidth = 1
        iconImageView.layer.borderColor = UIColor.separator.cgColor
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 64),
            iconImageView.heightAnchor.constraint(equalToConstant: 64)
        ])
        
        if let iconURL = installedApp.storeApp?.iconURL {
            Nuke.loadImage(with: iconURL, into: iconImageView)
        } else {
            iconImageView.image = UIImage(systemName: "app.fill")
            iconImageView.tintColor = .altPrimary
        }
        
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 4
        
        let nameLabel = UILabel()
        nameLabel.text = installedApp.name
        nameLabel.font = .systemFont(ofSize: 22, weight: .bold)
        nameLabel.textColor = .label
        
        let versionLabel = UILabel()
        versionLabel.text = "Version \(installedApp.version) • \(installedApp.bundleIdentifier)"
        versionLabel.font = .systemFont(ofSize: 13, weight: .regular)
        versionLabel.textColor = .secondaryLabel
        versionLabel.numberOfLines = 2
        
        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(versionLabel)
        
        headerStack.addArrangedSubview(iconImageView)
        headerStack.addArrangedSubview(infoStack)
        contentStackView.addArrangedSubview(headerStack)
        
        // 2. Current Save State Card
        let stateCard = UIView()
        stateCard.backgroundColor = .secondarySystemGroupedBackground
        stateCard.layer.cornerRadius = 18
        stateCard.layer.cornerCurve = .continuous
        stateCard.layer.borderWidth = 1
        stateCard.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        stateCard.addSubview(cardStack)
        
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: stateCard.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: stateCard.leadingAnchor, constant: 18),
            cardStack.trailingAnchor.constraint(equalTo: stateCard.trailingAnchor, constant: -18),
            cardStack.bottomAnchor.constraint(equalTo: stateCard.bottomAnchor, constant: -18)
        ])
        
        let sectionTitle = UILabel()
        sectionTitle.text = "CURRENT SAVE STATE"
        sectionTitle.font = .systemFont(ofSize: 12, weight: .heavy)
        sectionTitle.textColor = .secondaryLabel
        cardStack.addArrangedSubview(sectionTitle)
        
        statusBadgeLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        cardStack.addArrangedSubview(statusBadgeLabel)
        
        let detailsStack = UIStackView()
        detailsStack.axis = .vertical
        detailsStack.spacing = 4
        
        lastModifiedLabel.font = .systemFont(ofSize: 14)
        lastModifiedLabel.textColor = .secondaryLabel
        sizeLabel.font = .systemFont(ofSize: 14)
        sizeLabel.textColor = .secondaryLabel
        
        detailsStack.addArrangedSubview(lastModifiedLabel)
        detailsStack.addArrangedSubview(sizeLabel)
        cardStack.addArrangedSubview(detailsStack)
        
        let backupBtn = createStyledButton(title: "Back Up Save Data", icon: "doc.on.doc.fill", isPrimary: true)
        backupBtn.addTarget(self, action: #selector(backupTapped), for: .touchUpInside)
        cardStack.addArrangedSubview(backupBtn)
        
        let secondaryBtnsStack = UIStackView()
        secondaryBtnsStack.axis = .horizontal
        secondaryBtnsStack.distribution = .fillEqually
        secondaryBtnsStack.spacing = 12
        
        restoreButton = createStyledButton(title: "Restore", icon: "arrow.down.doc.fill", isPrimary: false)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        
        exportButton = createStyledButton(title: "Export .zip", icon: "square.and.arrow.up", isPrimary: false)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        
        secondaryBtnsStack.addArrangedSubview(restoreButton)
        secondaryBtnsStack.addArrangedSubview(exportButton)
        cardStack.addArrangedSubview(secondaryBtnsStack)
        
        contentStackView.addArrangedSubview(stateCard)
        
        // 3. Rollback & Import Card
        rollbackCard = UIView()
        rollbackCard.backgroundColor = .secondarySystemGroupedBackground
        rollbackCard.layer.cornerRadius = 18
        rollbackCard.layer.cornerCurve = .continuous
        rollbackCard.layer.borderWidth = 1
        rollbackCard.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        
        let advStack = UIStackView()
        advStack.axis = .vertical
        advStack.spacing = 16
        advStack.translatesAutoresizingMaskIntoConstraints = false
        rollbackCard.addSubview(advStack)
        
        NSLayoutConstraint.activate([
            advStack.topAnchor.constraint(equalTo: rollbackCard.topAnchor, constant: 18),
            advStack.leadingAnchor.constraint(equalTo: rollbackCard.leadingAnchor, constant: 18),
            advStack.trailingAnchor.constraint(equalTo: rollbackCard.trailingAnchor, constant: -18),
            advStack.bottomAnchor.constraint(equalTo: rollbackCard.bottomAnchor, constant: -18)
        ])
        
        let advTitle = UILabel()
        advTitle.text = "ADVANCED DATA OPTIONS"
        advTitle.font = .systemFont(ofSize: 12, weight: .heavy)
        advTitle.textColor = .secondaryLabel
        advStack.addArrangedSubview(advTitle)
        
        rollbackButton = createStyledButton(title: "Rollback to Previous Backup", icon: "clock.arrow.2.circlepath", isPrimary: false)
        rollbackButton.addTarget(self, action: #selector(rollbackTapped), for: .touchUpInside)
        advStack.addArrangedSubview(rollbackButton)
        
        let importBtn = createStyledButton(title: "Import Save (.zip)...", icon: "square.and.arrow.down", isPrimary: false)
        importBtn.addTarget(self, action: #selector(importTapped), for: .touchUpInside)
        advStack.addArrangedSubview(importBtn)
        
        contentStackView.addArrangedSubview(rollbackCard)
    }
    
    private func createStyledButton(title: String, icon: String, isPrimary: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 8
        config.cornerStyle = .medium
        if isPrimary {
            config.baseBackgroundColor = .altPrimary
            config.baseForegroundColor = .white
        } else {
            config.baseBackgroundColor = UIColor.secondarySystemFill
            config.baseForegroundColor = .altPrimary
        }
        btn.configuration = config
        btn.heightAnchor.constraint(equalToConstant: 46).isActive = true
        return btn
    }
    
    private func refreshData() {
        guard let backupURL = FileManager.default.backupDirectoryURL(for: installedApp) else { return }
        
        var backupExists = false
        if #available(iOS 13.0, *) {
            #if DEBUG && targetEnvironment(simulator)
            backupExists = true
            #else
            backupExists = FileManager.default.fileExists(atPath: backupURL.path)
            #endif
        }
        
        if backupExists {
            statusBadgeLabel.text = "✅ Save Data Protected"
            statusBadgeLabel.textColor = .systemGreen
            
            let size = calculateDirectorySize(at: backupURL)
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useKB]
            formatter.countStyle = .file
            sizeLabel.text = "Size: " + formatter.string(fromByteCount: size)
            
            if let attrs = try? FileManager.default.attributesOfItem(atPath: backupURL.path),
               let modDate = attrs[.modificationDate] as? Date {
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .short
                lastModifiedLabel.text = "Last Backed Up: " + df.string(from: modDate)
            } else {
                lastModifiedLabel.text = "Last Backed Up: Recent"
            }
            
            restoreButton.isEnabled = installedApp.isActive
            restoreButton.alpha = installedApp.isActive ? 1.0 : 0.5
            exportButton.isEnabled = true
            exportButton.alpha = 1.0
        } else {
            statusBadgeLabel.text = "⚠️ No Save State Backed Up"
            statusBadgeLabel.textColor = .systemOrange
            lastModifiedLabel.text = "Create a backup before updating or deleting this app."
            sizeLabel.text = "Size: 0 KB"
            
            restoreButton.isEnabled = false
            restoreButton.alpha = 0.5
            exportButton.isEnabled = false
            exportButton.alpha = 0.5
        }
        
        let prevURL = ImportExport.getPreviousBackupURL(backupURL)
        let prevExists = FileManager.default.fileExists(atPath: prevURL.path)
        rollbackButton.isHidden = !prevExists
    }
    
    private func calculateDirectorySize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return 0 }
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let vals = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let s = vals.fileSize {
                totalSize += Int64(s)
            }
        }
        return totalSize
    }
    
    @objc private func backupTapped() {
        myAppsViewController?.backup(installedApp)
    }
    
    @objc private func restoreTapped() {
        myAppsViewController?.restore(installedApp)
    }
    
    @objc private func exportTapped() {
        myAppsViewController?.exportBackup(for: installedApp)
    }
    
    @objc private func importTapped() {
        myAppsViewController?.importBackup(for: installedApp)
    }
    
    @objc private func rollbackTapped() {
        myAppsViewController?.restorePreviousBackup(for: installedApp)
    }
}
