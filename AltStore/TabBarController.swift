//
//  TabBarController.swift
//  AltStore
//
//  Created by Riley Testut on 9/19/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit
import AltStoreCore

extension TabBarController
{
    enum Tab: Int, CaseIterable
    {
        case browse
        case myApps
        case settings
    }
}

final class TabBarController: UITabBarController
{
    private var initialSegue: (identifier: String, sender: Any?)?
    private var _viewDidAppear = false
    private var didConfigurePrimaryTabs = false

    private let floatingTabBarBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private var floatingTabBarBackgroundConstraints: [NSLayoutConstraint] = []

    /// Builds the main tab interface from storyboard scenes (does not rely on tab-bar relationship segues).
    static func makeMainInterface() -> TabBarController {
        let tabBar = TabBarController()
        tabBar.configurePrimaryTabs()
        return tabBar
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        registerForNotifications()
    }

    init()
    {
        super.init(nibName: nil, bundle: nil)
        registerForNotifications()
    }

    private func registerForNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.importApp(_:)), name: AppDelegate.importAppDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.presentSources(_:)), name: AppDelegate.addSourceDeepLinkNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.exportFiles(_:)), name: AppDelegate.exportCertificateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabBarController.openErrorLog(_:)), name: ToastView.openErrorLogNotification, object: nil)
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureTabBarAppearance()
        if !didConfigurePrimaryTabs {
            configurePrimaryTabs()
        }
    }

    private func configurePrimaryTabs()
    {
        guard !didConfigurePrimaryTabs else { return }
        didConfigurePrimaryTabs = true

        let main = UIStoryboard(name: "Main", bundle: nil)
        let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)

        let browseNavigationController = main.instantiateViewController(withIdentifier: "browseNavigationController") as! UINavigationController
        browseNavigationController.tabBarItem.title = NSLocalizedString("Browse", comment: "")
        browseNavigationController.tabBarItem.image = UIImage(systemName: "square.grid.3x3.fill")
        browseNavigationController.navigationBar.prefersLargeTitles = true

        if browseNavigationController.viewControllers.isEmpty {
            let featured = main.instantiateViewController(withIdentifier: "featuredViewController") as! FeaturedViewController
            featured.navigationItem.largeTitleDisplayMode = .always
            configureFeaturedBrowseActions(featured)
            browseNavigationController.setViewControllers([featured], animated: false)
        } else if let featured = browseNavigationController.viewControllers.first as? FeaturedViewController {
            configureFeaturedBrowseActions(featured)
        }

        let myAppsNavigationController = main.instantiateViewController(withIdentifier: "myAppsNavigationController") as! UINavigationController
        myAppsNavigationController.tabBarItem.title = NSLocalizedString("My Apps", comment: "")
        myAppsNavigationController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        myAppsNavigationController.navigationBar.prefersLargeTitles = true

        let settingsNavigationController = settingsStoryboard.instantiateInitialViewController() as! UINavigationController
        settingsNavigationController.navigationBar.prefersLargeTitles = true
        settingsNavigationController.tabBarItem.title = NSLocalizedString("Settings", comment: "")
        settingsNavigationController.tabBarItem.image = UIImage(systemName: "gearshape.fill")

        viewControllers = [
            browseNavigationController,
            myAppsNavigationController,
            settingsNavigationController,
        ]
        selectedIndex = Tab.browse.rawValue
    }

    private func configureFeaturedBrowseActions(_ featured: FeaturedViewController)
    {
        let addCatalogAction = UIAction { [weak featured] _ in
            guard let nav = featured?.navigationController else { return }
            let add = FluxAddCatalogViewController()
            let sheet = UINavigationController(rootViewController: add)
            sheet.modalPresentationStyle = .formSheet
            sheet.navigationBar.prefersLargeTitles = false
            nav.present(sheet, animated: true)
        }
        let addHost = UIButton(type: .system)
        addHost.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addHost.addAction(addCatalogAction, for: .touchUpInside)
        addHost.accessibilityLabel = NSLocalizedString("Add catalog", comment: "")
        featured.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addHost)
    }

    private func configureTabBarAppearance()
    {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .separator
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.fluxSecondaryText
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.fluxSecondaryText,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = .altPrimary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.altPrimary,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .altPrimary
        tabBar.unselectedItemTintColor = .fluxSecondaryText
        tabBar.isTranslucent = false

        if #available(iOS 26.0, *)
        {
            floatingTabBarBackgroundView.isHidden = true
            return
        }

        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true

        floatingTabBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        floatingTabBarBackgroundView.isUserInteractionEnabled = false
        floatingTabBarBackgroundView.clipsToBounds = false
        floatingTabBarBackgroundView.layer.cornerRadius = 24
        floatingTabBarBackgroundView.layer.cornerCurve = .continuous
        floatingTabBarBackgroundView.layer.shadowColor = UIColor.black.cgColor
        floatingTabBarBackgroundView.layer.shadowOpacity = 0.10
        floatingTabBarBackgroundView.layer.shadowRadius = 18
        floatingTabBarBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 6)
        applyFloatingTabBarVisualStyle()

        tabBar.insertSubview(floatingTabBarBackgroundView, at: 0)
        updateFloatingTabBarConstraintsIfNeeded()
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        updateFloatingTabBarConstraintsIfNeeded()
        guard !floatingTabBarBackgroundView.isHidden else { return }
        floatingTabBarBackgroundView.layer.shadowPath = UIBezierPath(
            roundedRect: floatingTabBarBackgroundView.bounds,
            cornerRadius: floatingTabBarBackgroundView.layer.cornerRadius
        ).cgPath
    }

    private func updateFloatingTabBarConstraintsIfNeeded()
    {
        guard floatingTabBarBackgroundView.superview === tabBar else { return }

        NSLayoutConstraint.deactivate(floatingTabBarBackgroundConstraints)
        floatingTabBarBackgroundConstraints.removeAll()

        floatingTabBarBackgroundConstraints = [
            floatingTabBarBackgroundView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            floatingTabBarBackgroundView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            floatingTabBarBackgroundView.topAnchor.constraint(equalTo: tabBar.topAnchor),
            floatingTabBarBackgroundView.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
        ]
        floatingTabBarBackgroundView.layer.cornerRadius = 0
        floatingTabBarBackgroundView.layer.shadowOpacity = 0

        NSLayoutConstraint.activate(floatingTabBarBackgroundConstraints)
        applyFloatingTabBarVisualStyle()
    }

    private func applyFloatingTabBarVisualStyle()
    {
        floatingTabBarBackgroundView.contentView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.94)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass
            || traitCollection.userInterfaceIdiom != previousTraitCollection?.userInterfaceIdiom
            else { return }
        updateFloatingTabBarConstraintsIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        _viewDidAppear = true

        if let (identifier, sender) = initialSegue
        {
            initialSegue = nil
            performSegue(withIdentifier: identifier, sender: sender)
        }
    }

    override func performSegue(withIdentifier identifier: String, sender: Any?)
    {
        guard _viewDidAppear else {
            initialSegue = (identifier, sender)
            return
        }

        super.performSegue(withIdentifier: identifier, sender: sender)
    }
}

extension TabBarController
{
    @objc func presentSources(_ sender: Any)
    {
        selectedIndex = Tab.browse.rawValue
    }
}

private extension TabBarController
{
    @objc func importApp(_ notification: Notification)
    {
        selectedIndex = Tab.myApps.rawValue
    }

    @objc func openErrorLog(_ notification: Notification)
    {
        presentSettings()
    }

    @objc func exportFiles(_ notification: Notification)
    {
        presentSettings()
    }

    func presentSettings()
    {
        selectedIndex = Tab.settings.rawValue
    }
}
