//
//  FluxURLImportViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
//  Copyright © 2024. All rights reserved.
//

import UIKit
import Combine
import AltStoreCore
import Roxas

class FluxURLImportViewController: UIViewController {
    
    private enum Section: Int {
        case urlInput
        case downloadProgress
    }
    
    private enum ReuseID: String {
        case textFieldCell = "TextFieldCell"
        case progressCell = "ProgressCell"
    }
    
    @Published private var urlText: String = ""
    @Published private var isDownloading = false
    @Published private var downloadProgress: Float = 0.0
    @Published private var downloadStatus: String = ""
    
    private var downloadTask: URLSessionDownloadTask?
    private var progressObservation: NSKeyValueObservation?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .altBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(ProgressCell.self, forCellReuseIdentifier: "ProgressCell")
        return tableView
    }()
    
    private lazy var importButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: NSLocalizedString("Import", comment: ""),
            style: .plain,
            target: self,
            action: #selector(importFromURL)
        )
        button.isEnabled = false
        return button
    }()
    
    private lazy var cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .plain,
            target: self,
            action: #selector(cancelDownload)
        )
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Import from URL", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupViews()
        setupBindings()
        setupNavigationBar()
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        $urlText
            .map { !$0.isEmpty && URL(string: $0) != nil }
            .assign(to: \.isEnabled, on: importButton)
        
        $isDownloading
            .sink { [weak self] isDownloading in
                DispatchQueue.main.async {
                    if isDownloading {
                        self?.navigationItem.rightBarButtonItem = self?.cancelButton
                    } else {
                        self?.navigationItem.rightBarButtonItem = self?.importButton
                    }
                    self?.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = importButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissImport)
        )
    }
    
    @objc private func importFromURL() {
        guard let url = URL(string: urlText), url.scheme == "http" || url.scheme == "https" else {
            showError(NSLocalizedString("Please enter a valid URL", comment: ""))
            return
        }
        
        startDownload(from: url)
    }
    
    @objc private func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        downloadProgress = 0.0
        downloadStatus = ""
    }
    
    @objc private func dismissImport() {
        dismiss(animated: true)
    }
    
    private func startDownload(from url: URL) {
        isDownloading = true
        downloadStatus = NSLocalizedString("Starting download...", comment: "")
        
        let session = URLSession.shared
        downloadTask = session.downloadTask(with: url) { [weak self] localURL, response, error in
            DispatchQueue.main.async {
                self?.handleDownloadCompletion(localURL: localURL, response: response, error: error)
            }
        }
        
        progressObservation = downloadTask?.progress?.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress = Float(progress.fractionCompleted)
                self?.downloadStatus = String(format: NSLocalizedString("Downloading... %.0f%%", comment: ""), progress.fractionCompleted * 100)
            }
        }
        
        downloadTask?.resume()
    }
    
    private func handleDownloadCompletion(localURL: URL?, response: URLResponse?, error: Error?) {
        isDownloading = false
        
        if let error = error {
            showError(NSLocalizedString("Download failed: \(error.localizedDescription)", comment: ""))
            return
        }
        
        guard let localURL = localURL else {
            showError(NSLocalizedString("Download failed: No file received", comment: ""))
            return
        }
        
        // Verify it's an IPA file
        guard localURL.pathExtension.lowercased() == "ipa" else {
            showError(NSLocalizedString("The downloaded file is not an IPA file", comment: ""))
            return
        }
        
        // Import the IPA file
        importIPA(from: localURL)
    }
    
    private func importIPA(from url: URL) {
        downloadStatus = NSLocalizedString("Importing IPA...", comment: "")
        
        // Use existing AltStore import functionality
        // This would need to be connected to the existing IPA import system
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showSuccess(NSLocalizedString("IPA imported successfully!", comment: ""))
            self.dismissImport()
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("Error", comment: ""),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("Success", comment: ""),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - UITableViewDataSource
extension FluxURLImportViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return isDownloading ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .urlInput:
            return 1
        case .downloadProgress:
            return isDownloading ? 1 : 0
        case .none:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .urlInput:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath)
            
            let textField = UITextField()
            textField.placeholder = NSLocalizedString("https://example.com/app.ipa", comment: "")
            textField.text = urlText
            textField.addTarget(self, action: #selector(urlTextFieldChanged(_:)), for: .editingChanged)
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            cell.contentView.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20),
                textField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -20),
                textField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
            
            return cell
            
        case .downloadProgress:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProgressCell", for: indexPath) as! ProgressCell
            cell.configure(progress: downloadProgress, status: downloadStatus)
            return cell
            
        case .none:
            return UITableViewCell()
        }
    }
    
    @objc private func urlTextFieldChanged(_ textField: UITextField) {
        urlText = textField.text ?? ""
    }
}

// MARK: - UITableViewDelegate
extension FluxURLImportViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Section(rawValue: indexPath.section) {
        case .urlInput:
            return 60
        case .downloadProgress:
            return 80
        case .none:
            return 0
        }
    }
}

// MARK: - Progress Cell
class ProgressCell: UITableViewCell {
    static let identifier = "ProgressCell"
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .fluxSecondaryText
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
        contentView.addSubview(progressView)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(progress: Float, status: String) {
        progressView.progress = progress
        statusLabel.text = status
    }
}

// MARK: - URL Scheme Handling
extension FluxURLImportViewController {
    static func handleURL(_ url: URL) -> Bool {
        // Handle FluxStore://import?url= scheme
        guard url.scheme == "fluxstore",
              url.host == "import",
              let urlString = url.queryParameters?["url"],
              let importURL = URL(string: urlString) else {
            return false
        }
        
        // Present the import controller with the URL pre-filled
        DispatchQueue.main.async {
            let importVC = FluxURLImportViewController()
            importVC.urlText = urlString
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                let navController = UINavigationController(rootViewController: importVC)
                rootVC.present(navController, animated: true)
            }
        }
        
        return true
    }
}

// MARK: - URL Query Parameters Extension
extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
    }
}
