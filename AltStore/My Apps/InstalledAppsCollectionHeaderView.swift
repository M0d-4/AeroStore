//
//  InstalledAppsCollectionHeaderView.swift
//  AltStore
//
//  Created by Riley Testut on 3/9/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import UIKit

final class InstalledAppsCollectionHeaderView: UICollectionReusableView
{
    let textLabel: UILabel
    let button: UIButton
    
    private let titleRow: UIStackView
    
    override init(frame: CGRect)
    {
        self.textLabel = UILabel()
        self.textLabel.translatesAutoresizingMaskIntoConstraints = false
        self.textLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        self.textLabel.accessibilityTraits.insert(.header)
        self.textLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        self.button = UIButton(type: .system)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        self.titleRow = UIStackView(arrangedSubviews: [self.textLabel, spacer, self.button])
        self.titleRow.axis = .horizontal
        self.titleRow.alignment = .center
        self.titleRow.spacing = 8
        self.titleRow.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frame)

        self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        
        self.addSubview(self.titleRow)
        
        NSLayoutConstraint.activate([
            self.titleRow.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            self.titleRow.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            self.titleRow.topAnchor.constraint(equalTo: self.topAnchor, constant: 2),
            self.titleRow.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
        ])
        
        self.preservesSuperviewLayoutMargins = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
