//
//  ProfileView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var orderViewModel = OrderViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Enhanced User Profile Header
                    if let user = authService.currentUser {
                        VStack(spacing: Spacing.lg) {
                            // Profile Picture
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.titanBlue, Color.titanOrange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            .cardShadow()

                            // User Info
                            VStack(spacing: Spacing.sm) {
                                Text(user.displayName)
                                    .font(.appTitle)
                                    .foregroundColor(.titanBlue)

                                Text(user.csufEmail)
                                    .font(.bodyText)
                                    .foregroundColor(.secondary)

                                // Verification Badge
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: user.isEmailVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(user.isEmailVerified ? .success : .warning)
                                    Text(user.isEmailVerified ? "Verified CSUF Student" : "Email Not Verified")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(user.isEmailVerified ? .success : .warning)
                                }
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                                .background(user.isEmailVerified ? Color.success.opacity(0.1) : Color.warning.opacity(0.1))
                                .cornerRadius(20)

                                // Rating
                                HStack(spacing: Spacing.xs) {
                                    ForEach(0..<5) { index in
                                        Image(systemName: index < Int(user.rating.rounded()) ? "star.fill" : "star")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    Text(String(format: "%.1f", user.rating))
                                        .font(.bodyText)
                                        .fontWeight(.semibold)
                                    Text("(\(user.totalRatings))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, Spacing.xl)
                    }

                    // Menu Items
                    VStack(spacing: Spacing.md) {

                        // My Activity Section
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "bag.fill",
                                title: "My Orders",
                                iconColor: .titanOrange,
                                destination: AnyView(OrdersListView())
                            )

                            Divider().padding(.leading, 60)

                            ProfileMenuItem(
                                icon: "list.bullet.rectangle",
                                title: "My Listings",
                                iconColor: .titanBlue,
                                destination: AnyView(MyListingsView())
                            )

                            Divider().padding(.leading, 60)

                            ProfileMenuItem(
                                icon: "plus.circle.fill",
                                title: "Sell an Item",
                                iconColor: .success,
                                destination: AnyView(SellItemView())
                            )
                        }
                        .background(Color.cardBackground)
                        .cardStyle()

                        // Settings Section
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "gear",
                                title: "Account Settings",
                                iconColor: .gray,
                                destination: AnyView(Text("Coming Soon"))
                            )

                            Divider().padding(.leading, 60)

                            ProfileMenuItem(
                                icon: "bell.fill",
                                title: "Notifications",
                                iconColor: .orange,
                                destination: AnyView(Text("Coming Soon"))
                            )

                            Divider().padding(.leading, 60)

                            ProfileMenuItem(
                                icon: "questionmark.circle",
                                title: "Help & Support",
                                iconColor: .info,
                                destination: AnyView(Text("Coming Soon"))
                            )
                        }
                        .background(Color.cardBackground)
                        .cardStyle()

                        // Logout Button
                        Button(action: {
                            authService.logout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title3)
                                Text("Logout")
                                    .font(.headline)
                            }
                            .foregroundColor(.danger)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Profile Menu Item Component
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let iconColor: Color
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                }

                Text(title)
                    .font(.bodyText)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
        }
    }
}

struct OrdersListView: View {
    @StateObject private var viewModel = OrderViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.orders.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bag")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No orders yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                ForEach(viewModel.orders) { order in
                    OrderRowView(order: order)
                }
            }
        }
        .navigationTitle("My Orders")
        .task {
            await viewModel.fetchOrders()
        }
        .refreshable {
            await viewModel.fetchOrders()
        }
    }
}

struct OrderRowView: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Order #\(order.id.prefix(8))")
                    .font(.headline)
                Spacer()
                Text(order.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }

            Text("\(order.items.count) item(s)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("Total: $\(order.totalAmount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(order.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch order.status {
        case .pending, .paymentProcessing:
            return .orange
        case .confirmed, .meetingScheduled:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    ProfileView()
}
