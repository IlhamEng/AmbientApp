//
//  AmbientDashboardView.swift
//  AmbientApp
//

import SwiftUI

/// Main UI reading state from SharedStateManager.
public struct AmbientDashboardView: View {
    @State private var isOverloaded: Bool = false
    @State private var lastUpdated: Date? = nil
    @State private var isStateValid: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(isOverloaded ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                        .frame(width: 180, height: 180)

                    Image(systemName: isOverloaded ? "battery.25" : "battery.100")
                        .font(.system(size: 80))
                        .foregroundStyle(isOverloaded ? .orange : .green)
                }

                VStack(spacing: 8) {
                    Text(isOverloaded ? "Social Battery Low" : "Social Battery Healthy")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(
                        isOverloaded
                        ? "High social fatigue detected. Consider enabling Recharge mode."
                        : "Physiological metrics are within normal range."
                    )
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("State Valid (4h window)")
                        Spacer()
                        Image(systemName: isStateValid ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundStyle(isStateValid ? .green : .gray)
                    }

                    if let lastUpdated {
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(lastUpdated, style: .time)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.subheadline)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.12)))
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    let newState = !isOverloaded
                    SharedStateManager.shared.setOverloaded(newState)
                    refreshState()
                }) {
                    Text(isOverloaded ? "Reset Battery State" : "Simulate Overload Alert")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isOverloaded ? Color.blue : Color.orange)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Ambient Battery")
            .onAppear {
                refreshState()
            }
        }
    }

    private func refreshState() {
        isOverloaded = SharedStateManager.shared.isOverloaded
        lastUpdated = SharedStateManager.shared.lastUpdated
        isStateValid = SharedStateManager.shared.isStateValid
    }
}
