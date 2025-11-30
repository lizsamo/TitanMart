//
//  TitanMartApp.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI
import StripePaymentSheet

@main
struct TitanMartApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var cartService = CartService.shared

    // TEMPORARY: Set to true to skip login and test app with mock data
    let skipLoginForDemo = true

    init() {
        // Configure Stripe with publishable key
        STPAPIClient.shared.publishableKey = "pk_test_51RvZyXBiDYRWLIKKrDjOvzzi5fEBtuGsd1G86eNXyt80sWH6MSZVOaKclH91I8fAGvFBDZfNfQlhPYKRU0hSThmQ00XmPXeDd2"
    }

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated || skipLoginForDemo {
                MainTabView()
                    .environmentObject(authService)
                    .environmentObject(cartService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
