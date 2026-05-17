//
//  FluxURLImportViewController.swift
//  aerostore
//
//  Created by aerostore Team on 5/12/2024.
//  Copyright © 2024. All rights reserved.
//

import UIKit

class FluxURLImportViewController: UIViewController {
    
    private lazy var urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("https://example.com/app.ipa", comment: "")
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var importButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Import", comment: ""), for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Import from URL", comment: "")
        self.view.backgroundColor = .systemBackground
        
        setupViews()
        setupNavigationBar()
    }
    
    private func setupViews() {
        view.addSubview(urlTextField)
        view.addSubview(importButton)
        
        NSLayoutConstraint.activate([
            urlTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            importButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 20),
            importButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            importButton.widthAnchor.constraint(equalToConstant: 120),
            importButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        importButton.addTarget(self, action: #selector(importFromURL), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissImport)
        )
    }
    
    @objc private func importFromURL() {
        guard let urlString = urlTextField.text, !urlString.isEmpty,
              let url = URL(string: urlString) else {
            showError(NSLocalizedString("Please enter a valid URL", comment: ""))
            return
        }
        
        // Validate URL scheme
        guard url.scheme == "http" || url.scheme == "https" else {
            showError(NSLocalizedString("URL must use http or https scheme", comment: ""))
            return
        }
        
        startDownload(from: url)
    }
    
    private func startDownload(from url: URL) {
        importButton.isEnabled = false
        urlTextField.isEnabled = false
        
        let session = URLSession.shared
        let task = session.downloadTask(with: url) { [weak self] localURL, response, error in
            DispatchQueue.main.async {
                self?.importButton.isEnabled = true
                self?.urlTextField.isEnabled = true
                self?.handleDownloadCompletion(localURL: localURL, response: response, error: error)
            }
        }
        
        task.resume()
    }
    
    private func handleDownloadCompletion(localURL: URL?, response: URLResponse?, error: Error?) {
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
        
        // Show success message
        let alert = UIAlertController(
            title: NSLocalizedString("Download Complete", comment: ""),
            message: NSLocalizedString("IPA file downloaded successfully. Import functionality will be available in the next update.", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
    
    @objc private func dismissImport() {
        dismiss(animated: true)
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
}
