//
//  FluxHomeViewController.swift
//  AltStore
//

import UIKit
import AltStoreCore

/// Home tab: FluxStore update, quick navigation, embedded Browse preview (same catalog as Featured), and app update summary.
final class FluxHomeViewController: UIViewController
{
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceVertical = true
        s.keyboardDismissMode = .onDrag
        return s
    }()

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.spacing = 20
        s.isLayoutMarginsRelativeArrangement = true
        s.layoutMargins = UIEdgeInsets(top: 12, left: 20, bottom: 28, right: 20)
        return s
    }()

    private let updateStack = UIStackView()

    private var embeddedFeatured: FeaturedViewController?
    private var featuredHeightConstraint: NSLayoutConstraint?

    private var fluxUpdate: FluxStoreGitHubRelease.UpdateInfo?
    private var pendingAppUpdatesCount = 0
    private var isFetchingRelease = false

    private let yourAppsTitle = UILabel()
    private let yourAppsSubtitle = UILabel()
    private lazy var yourAppsCard: UIView = self.makeYourAppsCard()

    init()
    {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder)
    {
        // Must not fatalError: state restoration / storyboards / previews call this and would SIGABRT.
        super.init(coder: coder)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        view.backgroundColor = .altBackground
        title = NSLocalizedString("Home", comment: "")
        navigationItem.largeTitleDisplayMode = .always

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        updateStack.axis = .vertical
        updateStack.spacing = 0
        stackView.addArrangedSubview(updateStack)

        stackView.addArrangedSubview(makeSectionHeading(
            title: NSLocalizedString("Discover", comment: ""),
            subtitle: NSLocalizedString("New & updated, categories, and featured apps from your catalogs—same as Browse.", comment: "")
        ))
        embedFeaturedBrowse()

        stackView.addArrangedSubview(makeSectionHeading(
            title: NSLocalizedString("Your apps", comment: ""),
            subtitle: nil
        ))
        stackView.addArrangedSubview(yourAppsCard)

        configureYourAppsSummary()
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        refreshSummary()
        refreshFluxRelease()
        embeddedFeatured?.collectionView.reloadData()
        embeddedFeatured?.collectionView.collectionViewLayout.invalidateLayout()
        embeddedFeatured?.collectionView.layoutIfNeeded()
        embeddedFeatured?.view.setNeedsLayout()
        embeddedFeatured?.view.layoutIfNeeded()
        DispatchQueue.main.async { [weak self] in
            guard let self, let cv = self.embeddedFeatured?.collectionView else { return }
            cv.layoutIfNeeded()
            let h = cv.collectionViewLayout.collectionViewContentSize.height
            self.updateEmbeddedFeaturedHeight(h)
        }
    }

    /// Called from embedded `FeaturedViewController` when compositional layout finishes sizing.
    func updateEmbeddedFeaturedHeight(_ height: CGFloat)
    {
        featuredHeightConstraint?.constant = max(height, 220)
        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
        }
    }

    private func refreshSummary()
    {
        let request = InstalledApp.supportedUpdatesFetchRequest()
        pendingAppUpdatesCount = (try? DatabaseManager.shared.viewContext.count(for: request)) ?? 0
        configureYourAppsSummary()
    }

    private func refreshFluxRelease()
    {
        guard !isFetchingRelease else { return }
        isFetchingRelease = true
        Task { @MainActor in
            defer { self.isFetchingRelease = false }
            self.fluxUpdate = await FluxStoreGitHubRelease.fetchNewerReleaseIfAvailable()
            self.rebuildUpdateBanner()
        }
    }

    private func rebuildUpdateBanner()
    {
        updateStack.arrangedSubviews.forEach { v in
            updateStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        guard let info = fluxUpdate else { return }

        let outer = UIView()
        outer.translatesAutoresizingMaskIntoConstraints = false

        let card = UIControl()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .fluxCardBackground
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fluxCardBorder.cgColor
        card.addAction(UIAction { _ in FluxStoreGitHubRelease.openUpdate(info) }, for: .touchUpInside)

        let icon = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .altPrimary
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .preferredFont(forTextStyle: .headline)
        title.textColor = .label
        title.numberOfLines = 2
        title.text = String(format: NSLocalizedString("Update to %@ available", comment: ""), info.versionString)
        title.isUserInteractionEnabled = false

        let sub = UILabel()
        sub.translatesAutoresizingMaskIntoConstraints = false
        sub.font = .preferredFont(forTextStyle: .subheadline)
        sub.textColor = .fluxSecondaryText
        sub.numberOfLines = 2
        sub.text = NSLocalizedString("Download the latest IPA from GitHub", comment: "")
        sub.isUserInteractionEnabled = false

        let chev = UIImageView(image: UIImage(systemName: "chevron.right"))
        chev.translatesAutoresizingMaskIntoConstraints = false
        chev.tintColor = .fluxSecondaryText
        chev.isUserInteractionEnabled = false

        card.addSubview(icon)
        card.addSubview(title)
        card.addSubview(sub)
        card.addSubview(chev)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: outer.trailingAnchor),
            card.topAnchor.constraint(equalTo: outer.topAnchor),
            card.bottomAnchor.constraint(equalTo: outer.bottomAnchor),

            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 32),
            icon.heightAnchor.constraint(equalToConstant: 32),

            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: chev.leadingAnchor, constant: -8),
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            sub.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            sub.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            sub.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            chev.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            chev.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        outer.addSubview(card)
        updateStack.addArrangedSubview(outer)
    }

    private func makeSectionHeading(title: String, subtitle: String?) -> UIView
    {
        let wrap = UIView()
        let t = UILabel()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.font = .preferredFont(forTextStyle: .title2)
        t.textColor = .label
        t.text = title
        t.numberOfLines = 0
        wrap.addSubview(t)
        var constraints: [NSLayoutConstraint] = [
            t.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            t.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            t.topAnchor.constraint(equalTo: wrap.topAnchor),
        ]
        if let subtitle, !subtitle.isEmpty
        {
            let s = UILabel()
            s.translatesAutoresizingMaskIntoConstraints = false
            s.font = .preferredFont(forTextStyle: .subheadline)
            s.textColor = .fluxSecondaryText
            s.text = subtitle
            s.numberOfLines = 0
            wrap.addSubview(s)
            constraints += [
                s.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
                s.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
                s.topAnchor.constraint(equalTo: t.bottomAnchor, constant: 4),
                s.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            ]
        }
        else
        {
            constraints.append(t.bottomAnchor.constraint(equalTo: wrap.bottomAnchor))
        }
        NSLayoutConstraint.activate(constraints)
        return wrap
    }

    private func embedFeaturedBrowse()
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let featured = storyboard.instantiateViewController(withIdentifier: "featuredViewController") as! FeaturedViewController
        featured.isEmbeddedHomePreview = true

        addChild(featured)
        let fv = featured.view!
        fv.translatesAutoresizingMaskIntoConstraints = false

        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(fv)

        let hc = fv.heightAnchor.constraint(equalToConstant: 520)
        featuredHeightConstraint = hc
        NSLayoutConstraint.activate([
            fv.topAnchor.constraint(equalTo: box.topAnchor),
            fv.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            fv.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            fv.bottomAnchor.constraint(equalTo: box.bottomAnchor),
            hc,
        ])

        stackView.addArrangedSubview(box)
        featured.didMove(toParent: self)
        embeddedFeatured = featured
    }

    private func makeYourAppsCard() -> UIView
    {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .fluxCardBackground
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fluxCardBorder.cgColor

        yourAppsTitle.translatesAutoresizingMaskIntoConstraints = false
        yourAppsTitle.font = .preferredFont(forTextStyle: .headline)
        yourAppsTitle.textColor = .label
        yourAppsTitle.numberOfLines = 2
        yourAppsTitle.isUserInteractionEnabled = false

        yourAppsSubtitle.translatesAutoresizingMaskIntoConstraints = false
        yourAppsSubtitle.font = .preferredFont(forTextStyle: .subheadline)
        yourAppsSubtitle.textColor = .fluxSecondaryText
        yourAppsSubtitle.numberOfLines = 2
        yourAppsSubtitle.isUserInteractionEnabled = false

        let icon = UIImageView(image: UIImage(systemName: "arrow.triangle.2.circlepath"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .altPrimary
        icon.contentMode = .scaleAspectFit

        card.addSubview(icon)
        card.addSubview(yourAppsTitle)
        card.addSubview(yourAppsSubtitle)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),

            yourAppsTitle.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            yourAppsTitle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            yourAppsTitle.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            yourAppsSubtitle.leadingAnchor.constraint(equalTo: yourAppsTitle.leadingAnchor),
            yourAppsSubtitle.trailingAnchor.constraint(equalTo: yourAppsTitle.trailingAnchor),
            yourAppsSubtitle.topAnchor.constraint(equalTo: yourAppsTitle.bottomAnchor, constant: 4),
            yourAppsSubtitle.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])

        return card
    }

    private func configureYourAppsSummary()
    {
        if pendingAppUpdatesCount == 0
        {
            yourAppsTitle.text = NSLocalizedString("No app updates pending", comment: "")
            yourAppsSubtitle.text = NSLocalizedString("Pull to refresh on My Apps after sources sync.", comment: "")
        }
        else
        {
            yourAppsTitle.text = String(format: NSLocalizedString("%lld updates available", comment: ""), Int64(pendingAppUpdatesCount))
            yourAppsSubtitle.text = NSLocalizedString("Open My Apps to install or refresh.", comment: "")
        }
    }
}
