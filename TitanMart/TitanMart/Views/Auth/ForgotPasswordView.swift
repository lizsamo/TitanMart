//
//  ForgotPasswordView.swift
//  TitanMart
//
//  Created by Claude Code
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showResetForm = false
    @State private var codeSent = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Reset Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 20)

                    if !codeSent {
                        // Step 1: Enter username to request reset code
                        VStack(spacing: 15) {
                            Text("Enter your username to receive a password reset code via your CSUF email.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)

                            TextField("Username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }

                            if let success = successMessage {
                                Text(success)
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                            }

                            Button(action: requestResetCode) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Send Reset Code")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(username.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(isLoading || username.isEmpty)
                        }
                    } else {
                        // Step 2: Enter code and new password
                        VStack(spacing: 15) {
                            Text("A verification code has been sent to your CSUF email. Enter the code and your new password below.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)

                            TextField("Verification Code", text: $verificationCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .autocorrectionDisabled()

                            SecureField("New Password", text: $newPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.oneTimeCode)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            SecureField("Confirm New Password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.oneTimeCode)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }

                            if let success = successMessage {
                                Text(success)
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                            }

                            Button(action: resetPassword) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Reset Password")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(isLoading || !isFormValid)

                            Button(action: { codeSent = false }) {
                                Text("Didn't receive code? Try again")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }

    private var isFormValid: Bool {
        !verificationCode.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6
    }

    private func requestResetCode() {
        errorMessage = nil
        successMessage = nil
        isLoading = true

        Task {
            do {
                let message = try await APIService.shared.forgotPassword(username: username)
                successMessage = message
                // Wait a moment to show success message
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                codeSent = true
            } catch let apiError as APIError {
                errorMessage = apiError.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func resetPassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }

        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }

        errorMessage = nil
        successMessage = nil
        isLoading = true

        Task {
            do {
                let message = try await APIService.shared.resetPassword(
                    username: username,
                    code: verificationCode,
                    newPassword: newPassword
                )
                successMessage = message
                // Wait a moment to show success message, then dismiss
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                dismiss()
            } catch let apiError as APIError {
                errorMessage = apiError.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    ForgotPasswordView()
}
