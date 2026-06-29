//
//  FluxAddCatalogViewController.swift
//

import UIKit
import AltStoreCore
import Nuke

/// Flux-branded add-catalog flow (replaces presenting SideStore’s legacy Add Source UI from Browse).
final class FluxAddCatalogViewController: UIViewController {

    private struct CommunityCatalog {
        let name: String
        let tagline: String
        let url: String
        let iconName: String
    }

    private let communityCatalogs: [CommunityCatalog] = [
        CommunityCatalog(name: "SideStore Community", tagline: "Community-maintained apps for SideStore & AeroStore.", url: "https://community-apps.sidestore.io/sidecommunity.json", iconName: "person.2.fill"),
        CommunityCatalog(name: "UTM", tagline: "Run virtual machines on your iOS device.", url: "https://alt.getutm.app", iconName: "desktopcomputer"),
        CommunityCatalog(name: "Provenance", tagline: "Multi-system retro console emulator.", url: "https://provenance-emu.com/apps.json", iconName: "gamecontroller.fill"),
        CommunityCatalog(name: "LiveContainer", tagline: "Run iOS applications inside JIT containers.", url: "https://github.com/LiveContainer/LiveContainer/releases/download/1.0/apps.json", iconName: "square.stack.3d.up.fill"),
        CommunityCatalog(name: "Flycast", tagline: "Dreamcast, Naomi & Atomiswave emulator.", url: "https://github.com/chachillie/Flycast-iOS/raw/refs/heads/main/flycast-ios.json", iconName: "opticaldisc"),
        CommunityCatalog(name: "StikDebug", tagline: "JIT and advanced debugging utilities.", url: "https://stikdebug.xyz/index.json", iconName: "ladybug.fill")
    ]

    var prefilledURL: URL?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let urlField = UITextField()
    private let pasteButton = UIButton(type: .system)
    private let previewButton = UIButton(type: .system)

    private let previewContainer = UIStackView()
    private let previewIconWrap = UIView()
    private let previewIcon = UIImageView()

    private let previewTitle = UILabel()
    private let previewSubtitle = UILabel()
    private let addButton = UIButton(type: .system)

    private let activity = UIActivityIndicatorView(style: .medium)

    private var fetchedSource: Source?
    private var didAutoPreview = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .altBackground
        title = NSLocalizedString("Add catalog", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive

        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        let logoHeader = UIStackView()
        logoHeader.axis = .vertical
        logoHeader.alignment = .center
        logoHeader.spacing = 0

        let logo = AeroLogoView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: 72),
            logo.heightAnchor.constraint(equalToConstant: 72),
        ])
        logoHeader.addArrangedSubview(logo)

        let intro = UILabel()
        intro.translatesAutoresizingMaskIntoConstraints = false
        intro.text = NSLocalizedString("Paste an AltStore-compatible catalog URL. aerostore shows a live preview—nothing is saved until you confirm.", comment: "")
        intro.font = .preferredFont(forTextStyle: .body)
        intro.textColor = UIColor.fluxSecondaryText
        intro.numberOfLines = 0

        urlField.translatesAutoresizingMaskIntoConstraints = false
        urlField.borderStyle = .roundedRect
        urlField.placeholder = "https://"
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.keyboardType = .URL
        urlField.backgroundColor = UIColor.fluxCardBackground
        urlField.textColor = .label

        pasteButton.setTitle(NSLocalizedString("Paste", comment: ""), for: .normal)
        pasteButton.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)

        previewButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.setTitle(NSLocalizedString("Preview catalog", comment: ""), for: .normal)
        previewButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        previewButton.backgroundColor = .altPrimary
        previewButton.setTitleColor(.white, for: .normal)
        previewButton.layer.cornerRadius = 14
        previewButton.layer.cornerCurve = .continuous
        previewButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        previewButton.addTarget(self, action: #selector(previewTapped), for: .touchUpInside)

        previewContainer.axis = .vertical
        previewContainer.spacing = 12
        previewContainer.isHidden = true
        previewContainer.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        previewContainer.isLayoutMarginsRelativeArrangement = true
        previewContainer.backgroundColor = UIColor.fluxCardBackground
        previewContainer.layer.cornerRadius = 18
        previewContainer.layer.cornerCurve = .continuous
        previewContainer.layer.borderWidth = 1
        previewContainer.layer.borderColor = UIColor.fluxCardBorder.cgColor

        previewIconWrap.translatesAutoresizingMaskIntoConstraints = false
        previewIcon.translatesAutoresizingMaskIntoConstraints = false
        previewIcon.layer.cornerRadius = 16
        previewIcon.layer.cornerCurve = .continuous
        previewIcon.clipsToBounds = true
        previewIcon.contentMode = .scaleAspectFill
        previewIcon.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)

        previewIconWrap.addSubview(previewIcon)
        NSLayoutConstraint.activate([
            previewIconWrap.heightAnchor.constraint(equalToConstant: 72),
            previewIcon.leadingAnchor.constraint(equalTo: previewIconWrap.leadingAnchor),
            previewIcon.centerYAnchor.constraint(equalTo: previewIconWrap.centerYAnchor),
            previewIcon.widthAnchor.constraint(equalToConstant: 64),
            previewIcon.heightAnchor.constraint(equalToConstant: 64),
        ])

        previewTitle.font = .systemFont(ofSize: 20, weight: .bold)
        previewTitle.textColor = .label
        previewTitle.numberOfLines = 0

        previewSubtitle.font = .preferredFont(forTextStyle: .subheadline)
        previewSubtitle.textColor = UIColor.fluxSecondaryText
        previewSubtitle.numberOfLines = 0

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle(NSLocalizedString("Add to aerostore", comment: ""), for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        addButton.backgroundColor = UIColor.refreshGreen
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 14
        addButton.layer.cornerCurve = .continuous
        addButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        addButton.isHidden = true
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.hidesWhenStopped = true

        let fieldRow = UIStackView(arrangedSubviews: [urlField, pasteButton])
        fieldRow.axis = .horizontal
        fieldRow.spacing = 10
        fieldRow.alignment = .center

        previewContainer.addArrangedSubview(previewIconWrap)
        previewContainer.addArrangedSubview(previewTitle)
        previewContainer.addArrangedSubview(previewSubtitle)

        stack.addArrangedSubview(logoHeader)
        stack.addArrangedSubview(intro)
        stack.addArrangedSubview(fieldRow)
        stack.addArrangedSubview(previewButton)
        stack.addArrangedSubview(activity)
        stack.addArrangedSubview(previewContainer)
        stack.addArrangedSubview(addButton)

        let communityHeaderWrap = UIStackView()
        communityHeaderWrap.axis = .vertical
        communityHeaderWrap.spacing = 4
        communityHeaderWrap.layoutMargins = UIEdgeInsets(top: 16, left: 0, bottom: 4, right: 0)
        communityHeaderWrap.isLayoutMarginsRelativeArrangement = true

        let communitySectionHeader = UILabel()
        communitySectionHeader.text = NSLocalizedString("Discover Community Catalogs", comment: "")
        communitySectionHeader.font = .systemFont(ofSize: 20, weight: .bold)
        communitySectionHeader.textColor = .label
        
        let communityIntro = UILabel()
        communityIntro.text = NSLocalizedString("Tap any catalog below to quickly load and install community apps.", comment: "")
        communityIntro.font = .preferredFont(forTextStyle: .subheadline)
        communityIntro.textColor = UIColor.fluxSecondaryText
        communityIntro.numberOfLines = 0

        communityHeaderWrap.addArrangedSubview(communitySectionHeader)
        communityHeaderWrap.addArrangedSubview(communityIntro)

        let communityStack = UIStackView()
        communityStack.axis = .vertical
        communityStack.spacing = 12
        communityStack.addArrangedSubview(communityHeaderWrap)
        
        for catalog in communityCatalogs {
            communityStack.addArrangedSubview(makeCommunityCatalogCard(catalog))
        }

        stack.addArrangedSubview(communityStack)

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

            urlField.heightAnchor.constraint(equalToConstant: 44),
        ])

        if let prefilledURL {
            urlField.text = prefilledURL.absoluteString
        }
    }

    private func makeCommunityCatalogCard(_ item: CommunityCatalog) -> UIView {
        let card = UIStackView()
        card.axis = .horizontal
        card.spacing = 14
        card.alignment = .center
        card.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        card.isLayoutMarginsRelativeArrangement = true
        card.backgroundColor = UIColor.fluxCardBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fluxCardBorder.cgColor

        let iconWrap = UIView()
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)
        iconWrap.layer.cornerRadius = 12
        iconWrap.layer.cornerCurve = .continuous

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 12
        iconView.layer.cornerCurve = .continuous
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .altPrimary
        iconView.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)
        if let img = UIImage(systemName: item.iconName) {
            iconView.image = img
        }

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),
        ])

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 3

        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = .label

        let tagLabel = UILabel()
        tagLabel.text = item.tagline
        tagLabel.font = .systemFont(ofSize: 13, weight: .regular)
        tagLabel.textColor = UIColor.fluxSecondaryText
        tagLabel.numberOfLines = 2

        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(tagLabel)

        let actionButton = UIButton(type: .system)
        actionButton.setTitle(NSLocalizedString("Select", comment: ""), for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        actionButton.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.15)
        actionButton.setTitleColor(.altPrimary, for: .normal)
        actionButton.layer.cornerRadius = 10
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)

        let action = UIAction { [weak self] _ in
            guard let self else { return }
            self.urlField.text = item.url.absoluteString
            self.previewTapped()
            self.scrollView.setContentOffset(.zero, animated: true)
        }
        actionButton.addAction(action, for: .touchUpInside)

        card.addArrangedSubview(iconView)
        card.addArrangedSubview(textStack)
        card.addArrangedSubview(actionButton)

        return card
    }

    private func prefillIfPossible() {
        if let u = prefilledURL {
            urlField.text = u.absoluteString
            urlFieldChanged()
        } else if let s = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let u = URL(string: s),
                  let scheme = u.scheme?.lowercased(),
                  ["http", "https"].contains(scheme) {
            urlField.placeholder = s
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if prefilledURL != nil, !didAutoPreview {
            didAutoPreview = true
            previewTapped()
        }
    }

    @objc private func pasteTapped() {
        if let s = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) {
            urlField.text = s
            urlFieldChanged()
        }
    }

    @objc private func urlFieldChanged() {
        fetchedSource = nil
        previewedURL = nil
        previewContainer.isHidden = true
        addButton.isHidden = true
    }

    @objc private func previewTapped() {
        guard let text = urlField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: text) else {
            presentSimpleAlert(title: NSLocalizedString("Invalid URL", comment: ""), message: NSLocalizedString("aerostore couldn’t parse that address.", comment: ""))
            return
        }

        previewButton.isEnabled = false
        activity.startAnimating()
        fetchedSource = nil
        previewedURL = nil
        previewContainer.isHidden = true
        addButton.isHidden = true
        previewIcon.image = nil

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let source = try await AppManager.shared.fetchSource(sourceURL: url, managedObjectContext: self.catalogContext)
                guard let moc = source.managedObjectContext else {
                    await MainActor.run {
                        self.activity.stopAnimating()
                        self.previewButton.isEnabled = true
                        self.presentSimpleAlert(
                            title: NSLocalizedString("Can’t load catalog", comment: ""),
                            message: NSLocalizedString("The preview could not be prepared. Try again.", comment: "")
                        )
                    }
                    return
                }
                let preview = await moc.performAsync {
                    (
                        name: source.name,
                        subtitleLine: source.subtitle ?? source.sourceURL.absoluteString,
                        iconURL: source.effectiveIconURL
                    )
                }
                await MainActor.run {
                    self.fetchedSource = source
                    self.previewedURL = url
                    self.previewTitle.text = preview.name
                    self.previewSubtitle.text = preview.subtitleLine
                    self.previewContainer.isHidden = false
                    self.addButton.isHidden = false
                    self.activity.stopAnimating()
                    self.previewButton.isEnabled = true

                    if let iconURL = preview.iconURL {
                        self.previewIcon.backgroundColor = .white
                        self.previewIcon.tintColor = nil
                        Nuke.loadImage(with: iconURL, into: self.previewIcon)
                    } else {
                        self.previewIcon.image = UIImage(systemName: "square.stack.3d.up.fill")
                        self.previewIcon.tintColor = .altPrimary
                        self.previewIcon.backgroundColor = UIColor.altPrimary.withAlphaComponent(0.12)
                    }
                }
            } catch {
                await MainActor.run {
                    self.activity.stopAnimating()
                    self.previewButton.isEnabled = true
                    self.presentSimpleAlert(title: NSLocalizedString("Can’t load catalog", comment: ""), message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func addTapped() {
        guard let url = previewedURL ?? fetchedSource?.sourceURL else { return }

        addButton.isEnabled = false
        activity.startAnimating()

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await AppManager.shared.addWithoutConfirmation(sourceURL: url)
                self.dismiss(animated: true)
            } catch is CancellationError {
                self.addButton.isEnabled = true
                self.activity.stopAnimating()
            } catch {
                self.addButton.isEnabled = true
                self.activity.stopAnimating()
                self.presentSimpleAlert(title: NSLocalizedString("Unable to add catalog", comment: ""), message: error.localizedDescription)
            }
        }
    }

    /// Sync alert only — avoids colliding with `UIViewController.presentAlert` (async) in AltStoreCore.
    private func presentSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        present(alert, animated: true)
    }
}
