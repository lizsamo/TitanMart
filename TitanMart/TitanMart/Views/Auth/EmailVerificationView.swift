//
//  EmailVerificationView.swift
//  TitanMart
//
//  Email verification screen for new user accounts
//

import SwiftUI

struct EmailVerificationView: View {
    let csufEmail: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared

    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isResending = false
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Verify Your Email")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("We sent a 6-digit verification code to:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        Text(csufEmail)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Code Input
                    VStack(spacing: 16) {
                        TextField("Enter 6-digit code", text: $verificationCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .padding(.horizontal)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Verify Button
                        Button(action: verifyEmail) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Verify Email")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verificationCode.count == 6 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(isLoading || verificationCode.count != 6)
                        .padding(.horizontal)
                    }

                    // Resend Code
                    VStack(spacing: 12) {
                        Text("Didn't receive the code?")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Button(action: resendCode) {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Resend Code")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .disabled(isResending)
                    }
                    .padding(.top, 20)

                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Email Verified!", isPresented: $showSuccess) {
                Button("Continue") {
                    dismiss()
                }
            } message: {
                Text("Your email has been successfully verified. You can now use all features of TitanMart!")
            }
        }
    }

    private func verifyEmail() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authService.verifyEmail(code: verificationCode)
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch let apiError as APIError {
                await MainActor.run {
                    errorMessage = apiError.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func resendCode() {
        errorMessage = nil
        isResending = true

        Task {
            do {
                try await authService.resendVerificationCode(csufEmail: csufEmail)
                await MainActor.run {
                    isResending = false
                    // Show success message
                    errorMessage = nil
                }
            } catch let apiError as APIError {
                await MainActor.run {
                    errorMessage = apiError.localizedDescription
                    isResending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isResending = false
                }
            }
        }
    }
}

#Preview {
    EmailVerificationView(csufEmail: "example@csu.fullerton.edu")
}
