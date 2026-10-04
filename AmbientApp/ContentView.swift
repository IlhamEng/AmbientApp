//
//  ContentView.swift
//  AmbientApp
//

import SwiftUI

struct ContentView: View {
    @State private var hasCompletedOnboarding: Bool = false

    var body: some View {
        if hasCompletedOnboarding {
            AmbientDashboardView()
        } else {
            PermissionView {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
}
