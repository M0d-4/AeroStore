//
//  FluxCatalogDetailViewController.swift
//

import UIKit
import AltStoreCore
import Nuke

/// Flux-branded catalog overview before opening the rich app browser.
final class FluxCatalogDetailViewController: UIViewController {

    private let source: Source

    init(source: Source) {
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .altBackground
        title = source.name

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 22
        stack.translatesAutoresizingMaskIntoConstraints = false

        let hero = UIView()
        hero.translatesAutoresizingMaskIntoConstraints = false
        hero.layer.cornerRadius = 24
        hero.layer.cornerCurve = .continuous
        hero.backgroundColor = UIColor.fluxCardBackground
        hero.layer.borderWidth = 1
        hero.layer.borderColor = UIColor.fluxCardBorder.cgColor

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.layer.cornerRadius = 22
        icon.layer.cornerCurve = .continuous
        icon.clipsToBounds = true
        icon.contentMode = .scaleAspectFill
        icon.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = source.name
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 0

        let hostLabel = UILabel()
        hostLabel.translatesAutoresizingMaskIntoConstraints = false
        hostLabel.text = source.sourceURL.host ?? source.sourceURL.absoluteString
        hostLabel.font = .preferredFont(forTextStyle: .footnote)
        hostLabel.textColor = UIColor.fluxSecondaryText

        hero.addSubview(icon)
        hero.addSubview(nameLabel)
        hero.addSubview(hostLabel)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 20),
            icon.topAnchor.constraint(equalTo: hero.topAnchor, constant: 20),
            icon.widthAnchor.constraint(equalToConstant: 88),
            icon.heightAnchor.constraint(equalToConstant: 88),

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -20),
            nameLabel.topAnchor.constraint(equalTo: hero.topAnchor, constant: 26),

            hostLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            hostLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            hostLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            hostLabel.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -22),
        ])

        let desc = UILabel()
        desc.translatesAutoresizingMaskIntoConstraints = false
        desc.text = source.subtitle ?? NSLocalizedString("Browse featured releases, screenshots, descriptions, and updates—the Flux catalog experience replaces the old SideStore source sheet.", comment: "")
        desc.font = .preferredFont(forTextStyle: .body)
        desc.textColor = UIColor.fluxSecondaryText
        desc.numberOfLines = 0

        let browse = UIButton(type: .system)
        browse.translatesAutoresizingMaskIntoConstraints = false
        browse.setTitle(NSLocalizedString("Browse catalog", comment: ""), for: .normal)
        browse.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        browse.backgroundColor = .altPrimary
        browse.setTitleColor(.white, for: .normal)
        browse.layer.cornerRadius = 16
        browse.layer.cornerCurve = .continuous
        browse.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        browse.addAction(UIAction { [weak self] _ in self?.openBrowse() }, for: .touchUpInside)

        stack.addArrangedSubview(hero)
        stack.addArrangedSubview(desc)
        stack.addArrangedSubview(browse)

        if let web = source.websiteURL {
            let site = UIButton(type: .system)
            site.setTitle(NSLocalizedString("Publisher website", comment: ""), for: .normal)
            site.titleLabel?.font = .preferredFont(forTextStyle: .body)
            site.addAction(UIAction { _ in UIApplication.shared.open(web) }, for: .touchUpInside)
            stack.addArrangedSubview(site)
        }

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])

        if let u = source.effectiveIconURL {
            icon.backgroundColor = .white
            Nuke.loadImage(with: u, into: icon)
        } else {
            icon.image = UIImage(systemName: "square.stack.3d.up.fill")
            icon.tintColor = .altPrimary
        }
    }

    private func openBrowse() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let browse = storyboard.instantiateViewController(identifier: "browseViewController") { coder in
            BrowseViewController(source: self.source, coder: coder)
        }
        navigationController?.pushViewController(browse, animated: true)
    }
}
