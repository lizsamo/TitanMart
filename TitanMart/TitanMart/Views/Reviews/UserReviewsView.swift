//
//  UserReviewsView.swift
//  TitanMart
//
//  View to display all reviews received by a user
//

import SwiftUI

struct UserReviewsView: View {
    let user: User

    @State private var reviews: [Review] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Rating Summary
                VStack(spacing: 10) {
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.title)
                        Text(String(format: "%.1f", user.rating))
                            .font(.system(size: 40, weight: .bold))
                    }

                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(user.rating.rounded()) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }

                    Text("\(user.totalRatings) \(user.totalRatings == 1 ? "review" : "reviews")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical)

                Divider()

                // Reviews List
                if isLoading {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if reviews.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "star.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No reviews yet")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 15) {
                        ForEach(reviews) { review in
                            ReviewCard(review: review)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadReviews()
        }
    }

    private func loadReviews() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedReviews = try await APIService.shared.fetchReviews(userId: user.csufEmail)

                await MainActor.run {
                    self.reviews = fetchedReviews
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load reviews"
                    self.isLoading = false
                }
            }
        }
    }
}

struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.reviewerName)
                        .font(.headline)

                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }

                Spacer()

                Text(timeAgo(from: review.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Comment
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)

        if let year = components.year, year > 0 {
            return "\(year)y ago"
        } else if let month = components.month, month > 0 {
            return "\(month)mo ago"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)w ago"
        } else if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

#Preview {
    NavigationStack {
        UserReviewsView(user: User(
            csufEmail: "test@csu.fullerton.edu",
            username: "testuser",
            fullName: "Test User",
            rating: 4.5,
            totalRatings: 10
        ))
    }
}
