//
//  UIKitTabView.swift
//  sup
//
//  Created by Robert Malko on 11/14/19.
//  Copyright © 2019 Episode 8, Inc.. All rights reserved.
//

import SwiftUI

/// An iOS style TabView that doesn't reset it's childrens navigation stacks
/// when tabs are switched.
struct UIKitTabView: View {
    var tabBarView: AnyView
    var viewControllers: [UIHostingController<AnyView>]
    @Binding var selectedIndex: Int

    init<V: View>(
        _ views: [Tab],
        _ tabBarView: V,
        _ selectedIndex: Binding<Int>
    ) {
        self._selectedIndex = selectedIndex
        self.tabBarView = AnyView(tabBarView)
        self.viewControllers = views.map {
            let host = UIHostingController(rootView: $0.view)
            return host
        }
    }

    var body: some View {
        TabBarController(
            controllers: viewControllers,
            tabBarView: tabBarView,
            selectedIndex: $selectedIndex
        ).edgesIgnoringSafeArea(.all)
    }

    struct Tab {
        var view: AnyView

        init<V: View>(_ view: V) {
            self.view = AnyView(view)
        }
    }
}

struct TabBarController: UIViewControllerRepresentable {
    var controllers: [UIViewController]
    var tabBarView: AnyView

    @Binding var selectedIndex: Int

    func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.tabBar.isHidden = true
        tabBarController.viewControllers = controllers
        tabBarController.selectedIndex = 0
        setupView(tabBarController: tabBarController)
        return tabBarController
    }

    private func setupView(tabBarController: UITabBarController) {
        let hostingController = UIHostingController(rootView: tabBarView)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.frame = tabBarController.view.bounds
        tabBarController.addChild(hostingController)
        let subview = PassthroughView(childView: hostingController.view)
        tabBarController.view.addSubview(subview)
        hostingController.didMove(toParent: tabBarController)
    }

    func updateUIViewController(
        _ tabBarController: UITabBarController, context: Context
    ) {
        tabBarController.selectedIndex = selectedIndex
    }
}
