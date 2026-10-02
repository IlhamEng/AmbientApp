//
//  PermissionView.swift
//  AmbientApp
//

import SwiftUI

/// Onboarding view providing explanations prior to requesting system permissions.
public struct PermissionView: View {
    @State private var permissionManager = PermissionManager()
    public var onContinue: () -> Void

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "battery.100.bolt")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("Ambient Social Battery")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Monitors your physiological indicators in the background to detect social fatigue and suggest recharge breaks.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HealthKit Access")
                            .font(.headline)
                        Text("Reads HRV SDNN and steps. Raw data is evaluated locally and never stored.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time-Sensitive Notifications")
                            .font(.headline)
                        Text("Alerts you when overload is detected with quick action buttons.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.12)))
            .padding(.horizontal)

            Spacer()

            Button(action: {
                Task {
                    await permissionManager.requestAllPermissions()
                    onContinue()
                }
            }) {
                Text("Grant Permissions & Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}
