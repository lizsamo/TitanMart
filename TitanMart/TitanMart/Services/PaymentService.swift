//
//  PaymentService.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/24/25.
//

import Foundation
import UIKit
@preconcurrency import StripePaymentSheet

class PaymentService: ObservableObject {
    static let shared = PaymentService()

    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    private init() {}

    /// Prepares the payment sheet for checkout
    func preparePaymentSheet(amount: Double, orderId: String) async throws {
        guard let token = AuthService.shared.getToken() else {
            throw APIError.unauthorized
        }

        // Get payment intent client secret from backend
        let clientSecret = try await APIService.shared.createPaymentIntent(
            amount: amount,
            orderId: orderId,
            token: token
        )

        // Configure payment sheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "TitanMart"
        configuration.allowsDelayedPaymentMethods = false

        // Create payment sheet
        let paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )

        await MainActor.run {
            self.paymentSheet = paymentSheet
        }
    }

    /// Presents the payment sheet and handles the result
    func presentPaymentSheet() async throws -> Bool {
        guard let paymentSheet = self.paymentSheet else {
            throw APIError.serverError("Payment sheet not initialized")
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                // Get the topmost view controller
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else {
                    continuation.resume(throwing: APIError.serverError("Unable to present payment sheet"))
                    return
                }

                // Find the topmost presented view controller
                var topViewController = rootViewController
                while let presented = topViewController.presentedViewController {
                    topViewController = presented
                }

                paymentSheet.present(from: topViewController) { result in
                    switch result {
                    case .completed:
                        continuation.resume(returning: true)
                    case .canceled:
                        continuation.resume(returning: false)
                    case .failed(let error):
                        continuation.resume(throwing: APIError.serverError("Payment failed: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }

    /// Complete payment flow: prepare and present payment sheet
    func processPayment(amount: Double, orderId: String) async throws -> Bool {
        try await preparePaymentSheet(amount: amount, orderId: orderId)
        return try await presentPaymentSheet()
    }
}
