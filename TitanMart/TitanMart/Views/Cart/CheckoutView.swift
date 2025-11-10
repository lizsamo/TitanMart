//
//  CheckoutView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI

struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var cartService = CartService.shared
    @StateObject private var orderViewModel = OrderViewModel()
    @StateObject private var paymentService = PaymentService.shared
    @State private var meetingLocation = "CSUF Campus - Pollak Library"
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Page Header
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.titanOrange)

                        Text("Checkout")
                            .font(.appTitle)
                            .foregroundColor(.titanBlue)

                        Text("Review your order and complete purchase")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Order Summary Card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "bag.fill")
                                .foregroundColor(.titanOrange)
                            Text("Order Summary")
                                .font(.sectionTitle)
                        }

                        ForEach(cartService.items) { item in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Text("•")
                                    .foregroundColor(.titanBlue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.product.title)
                                        .font(.bodyText)
                                    Text("Qty: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("$\(item.totalPrice, specifier: "%.2f")")
                                    .font(.bodyText)
                                    .fontWeight(.semibold)
                            }
                        }

                        Divider()

                        HStack {
                            Text("Total")
                                .font(.sectionTitle)
                                .fontWeight(.bold)
                            Spacer()
                            Text("$\(cartService.totalPrice, specifier: "%.2f")")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.titanOrange)
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cardStyle()

                    // Meeting Location Card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.titanOrange)
                            Text("Pickup Location")
                                .font(.sectionTitle)
                        }

                        TextField("Enter meeting location", text: $meetingLocation)
                            .padding(Spacing.md)
                            .background(Color(.systemGray6))
                            .cornerRadius(CornerRadius.small)

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.info)
                            Text("Coordinate a safe pickup location on campus with the seller")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cardStyle()

                    // Payment Info Card
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.success)
                            Text("Secure Payment")
                                .font(.sectionTitle)
                        }

                        HStack(spacing: Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.titanBlue, Color.titanBlue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 60, height: 40)

                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Powered by Stripe")
                                    .font(.bodyText)
                                    .fontWeight(.semibold)
                                Text("Your payment is secure and encrypted")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.caption)
                                .foregroundColor(.success)
                            Text("Payment held in escrow until you confirm receipt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(Spacing.lg)
                    .background(Color.cardBackground)
                    .cardStyle()

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    // Place Order Button
                    Button(action: placeOrder) {
                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Processing...")
                                    .foregroundColor(.white)
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Place Order")
                                Text("$\(cartService.totalPrice, specifier: "%.2f")")
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isProcessing)
                    .padding(.bottom, Spacing.lg)
                }
                .padding()
            }
            .navigationTitle("Checkout")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Payment Successful!", isPresented: $showingSuccess) {
                Button("OK") {
                    cartService.clearCart()
                    isProcessing = false
                    dismiss()
                }
            } message: {
                Text("Your payment has been processed and order confirmed. The seller will contact you to arrange pickup.")
            }
        }
    }

    private func placeOrder() {
        errorMessage = nil
        isProcessing = true

        Task {
            do {
                // Step 1: Create the order first (to get orderId)
                let order = try await orderViewModel.createOrder(items: cartService.items)

                // Step 2: Process payment with Stripe
                let paymentSucceeded = try await paymentService.processPayment(
                    amount: order.totalAmount,
                    orderId: order.id
                )

                // Step 3: Handle payment result
                if paymentSucceeded {
                    showingSuccess = true
                } else {
                    errorMessage = "Payment was cancelled"
                    isProcessing = false
                }
            } catch let apiError as APIError {
                errorMessage = apiError.localizedDescription
                isProcessing = false
            } catch {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }
}

#Preview {
    CheckoutView()
}
