//
//  CartView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI

struct CartView: View {
    @StateObject private var cartService = CartService.shared
    @State private var showingCheckout = false

    var body: some View {
        NavigationView {
            Group {
                if cartService.items.isEmpty {
                    // Enhanced Empty State
                    VStack(spacing: Spacing.lg) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.titanBlue.opacity(0.1), Color.titanOrange.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)

                            Image(systemName: "cart.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.titanBlue)
                        }

                        VStack(spacing: Spacing.sm) {
                            Text("Your cart is empty")
                                .font(.sectionTitle)
                                .fontWeight(.bold)

                            Text("Start shopping and add items to your cart")
                                .font(.bodyText)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Spacer()
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Cart Items
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(cartService.items) { item in
                                    CartItemRow(item: item)
                                }
                            }
                            .padding()
                        }

                        // Enhanced Summary Section
                        VStack(spacing: 0) {
                            Divider()

                            VStack(spacing: Spacing.md) {
                                // Item count
                                HStack {
                                    Text("Items")
                                        .font(.bodyText)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(cartService.itemCount)")
                                        .font(.bodyText)
                                        .fontWeight(.semibold)
                                }

                                // Subtotal
                                HStack {
                                    Text("Subtotal")
                                        .font(.sectionTitle)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("$\(cartService.totalPrice, specifier: "%.2f")")
                                        .font(.priceText)
                                        .foregroundColor(.titanOrange)
                                }

                                // Checkout Button
                                Button(action: { showingCheckout = true }) {
                                    HStack {
                                        Text("Proceed to Checkout")
                                        Image(systemName: "arrow.right")
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .padding(.top, Spacing.sm)
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(.systemBackground), Color.titanBlue.opacity(0.03)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                }
            }
            .navigationTitle("Shopping Cart")
            .sheet(isPresented: $showingCheckout) {
                CheckoutView()
            }
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    @StateObject private var cartService = CartService.shared

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Product Image with gradient
            ZStack {
                LinearGradient(
                    colors: [Color.titanBlue.opacity(0.3), Color.titanOrange.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 90, height: 90)

                Image(systemName: categoryIcon(for: item.product.category))
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            .cornerRadius(CornerRadius.medium)

            // Product Details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.product.title)
                    .font(.cardTitle)
                    .lineLimit(2)

                HStack(spacing: Spacing.xs) {
                    Text(item.product.condition.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(conditionColor(for: item.product.condition))
                        .cornerRadius(6)

                    Text(item.product.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("$\(item.product.price, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.titanOrange)
            }

            Spacer()

            // Quantity Controls
            VStack(spacing: Spacing.sm) {
                // Quantity stepper
                VStack(spacing: 4) {
                    Button(action: {
                        cartService.updateQuantity(for: item, quantity: item.quantity + 1)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.titanBlue)
                    }

                    Text("\(item.quantity)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(width: 30)

                    Button(action: {
                        cartService.updateQuantity(for: item, quantity: item.quantity - 1)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(item.quantity > 1 ? .titanBlue : .gray)
                    }
                    .disabled(item.quantity <= 1)
                }

                // Remove button
                Button(action: {
                    withAnimation {
                        cartService.removeFromCart(item)
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cardShadow()
        .cornerRadius(CornerRadius.medium)
    }

    private func categoryIcon(for category: ProductCategory) -> String {
        switch category {
        case .textbooks: return "book.fill"
        case .electronics: return "laptopcomputer"
        case .furniture: return "chair.fill"
        case .clothing: return "tshirt.fill"
        case .supplies: return "pencil.and.list.clipboard"
        case .tickets: return "ticket.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    private func conditionColor(for condition: ProductCondition) -> Color {
        switch condition {
        case .new: return Color.green
        case .likeNew: return Color.blue
        case .good: return Color.orange
        case .fair: return Color.orange.opacity(0.7)
        case .poor: return Color.red
        }
    }
}

#Preview {
    CartView()
}
