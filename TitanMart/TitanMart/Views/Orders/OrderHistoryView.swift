//
//  OrderHistoryView.swift
//  TitanMart
//
//  View to display user's order history with review functionality
//

import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderViewModel()
    @State private var selectedOrderForReview: Order?
    @State private var showLeaveReview = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchOrders()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if viewModel.orders.filter({ $0.buyerId == AuthService.shared.currentUser?.csufEmail }).isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "bag")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No orders yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Your order history will appear here")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.orders.filter { $0.buyerId == AuthService.shared.currentUser?.csufEmail }.sorted(by: { $0.createdAt > $1.createdAt })) { order in
                            OrderCard(order: order) {
                                selectedOrderForReview = order
                                showLeaveReview = true
                            }
                            .environmentObject(viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Order History")
        .onAppear {
            Task {
                await viewModel.fetchOrders()
            }
        }
        .refreshable {
            await viewModel.fetchOrders()
        }
        .sheet(item: $selectedOrderForReview) { order in
            ReviewSheetView(order: order)
        }
    }
}

struct OrderCard: View {
    let order: Order
    let onReviewTapped: () -> Void

    @EnvironmentObject var viewModel: OrderViewModel
    @State private var canReview = false
    @State private var reviewReason: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Order Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.id.prefix(8))")
                        .font(.headline)

                    Text(order.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                StatusBadge(status: order.status)
            }

            // Order Items
            ForEach(Array(order.items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 10) {
                    if let imageURL = item.product.imageURLs.first,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.product.title)
                            .font(.subheadline)
                        Text("Qty: \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text("$\(item.totalPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            Divider()

            // Total and Other Party
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let otherPartyName = viewModel.getOtherPartyName(for: order) {
                        Text(order.buyerId == AuthService.shared.currentUser?.csufEmail ? "Seller: \(otherPartyName)" : "Buyer: \(otherPartyName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Text("Total: $\(order.totalAmount, specifier: "%.2f")")
                    .font(.headline)
            }

            // Review Button (only for completed orders and when current user is the buyer)
            if order.status == .completed && order.buyerId == AuthService.shared.currentUser?.csufEmail {
                Button(action: onReviewTapped) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Leave Review for Seller")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .task {
                    await checkReviewEligibility()
                }
                .disabled(!canReview)
                .opacity(canReview ? 1.0 : 0.5)
            }

            if let reason = reviewReason, !canReview {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func checkReviewEligibility() async {
        guard let otherPartyId = viewModel.getOtherPartyUserId(for: order) else {
            return
        }

        let result = await viewModel.canReview(orderId: order.id, reviewedUserId: otherPartyId)
        await MainActor.run {
            canReview = result.canReview
            reviewReason = result.reason
        }
    }
}

struct ReviewSheetView: View {
    let order: Order

    @Environment(\.dismiss) private var dismiss
    @State private var reviewedUser: User?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.gray)
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let user = reviewedUser {
                LeaveReviewView(order: order, reviewedUser: user)
            }
        }
        .task {
            await loadReviewedUser()
        }
    }

    private func loadReviewedUser() async {
        guard let otherPartyId = OrderViewModel().getOtherPartyUserId(for: order) else {
            errorMessage = "Could not determine who to review"
            isLoading = false
            return
        }

        do {
            let user = try await APIService.shared.getUserProfile(csufEmail: otherPartyId)
            await MainActor.run {
                reviewedUser = user
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load user profile"
                isLoading = false
            }
        }
    }
}

struct StatusBadge: View {
    let status: OrderStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status {
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
    NavigationStack {
        OrderHistoryView()
    }
}
