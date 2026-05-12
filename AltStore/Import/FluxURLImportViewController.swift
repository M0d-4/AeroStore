//
//  FluxURLImportViewController.swift
//  FluxStore
//
//  Created by FluxStore Team on 5/12/2024.
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
        button.backgroundColor = .altPrimary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Import from URL", comment: "")
        self.view.backgroundColor = .altBackground
        
        setupViews()
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
    
    @objc private func importFromURL() {
        guard let urlString = urlTextField.text, !urlString.isEmpty,
              let url = URL(string: urlString) else {
            showError(NSLocalizedString("Please enter a valid URL", comment: ""))
            return
        }
        
        // TODO: Implement actual URL download functionality
        let alert = UIAlertController(
            title: NSLocalizedString("URL Import", comment: ""),
            message: NSLocalizedString("URL import functionality will be implemented soon.", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
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
