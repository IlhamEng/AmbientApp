//
//  EnableRechargeIntent.swift
//  AmbientApp
//

import Foundation
import AppIntents

/// AppIntent for enabling Recharge Mode intervention via system Shortcuts, Siri, and notification actions.
public struct EnableRechargeIntent: AppIntent {

    public static var title: LocalizedStringResource = "Enable Recharge Mode"
    public static var description = IntentDescription(
        "Activates Recharge Mode in SharedStateManager to help recover your social battery."
    )

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        // Update App Group shared state
        SharedStateManager.shared.setOverloaded(true)

        let dialogText = IntentDialog("Recharge Mode activated successfully.")
        return await .result(dialog: dialogText)
    }
}
