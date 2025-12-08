//
//  LoginView.swift
//  TitanMart
//
//  Created by Elizsa Montoya on 10/22/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSignup = false
    @State private var showingForgotPassword = false
    @State private var showingVerification = false
    @State private var userEmailToVerify = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo and Title
                VStack(spacing: 10) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("TitanMart")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("CSUF Student Marketplace")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 40)

                // Login Form
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading)

                    // Forgot Password Link
                    Button(action: { showingForgotPassword = true }) {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal)

                // Sign Up Link
                Button(action: { showingSignup = true }) {
                    Text("Don't have an account? Sign Up")
                        .font(.subheadline)
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignup) {
                SignupView()
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .fullScreenCover(isPresented: $showingVerification) {
                EmailVerificationView(csufEmail: userEmailToVerify)
            }
        }
    }

    private func login() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authService.login(username: username, password: password)

                // Check if user needs to verify email
                await MainActor.run {
                    if let user = authService.currentUser, !user.isEmailVerified {
                        userEmailToVerify = user.csufEmail
                        showingVerification = true
                    }
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
}

#Preview {
    LoginView()
}
