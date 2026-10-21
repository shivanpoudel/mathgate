import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: .white,
            icon: nil,
            title: .init(text: "MathGate", color: .black),
            subtitle: .init(text: "Ten correct answers before \(application.localizedDisplayName ?? "this app").", color: .darkGray),
            primaryButtonLabel: .init(text: "Solve questions", color: .white),
            primaryButtonBackgroundColor: .black,
            secondaryButtonLabel: .init(text: "Not now", color: .darkGray))
    }
}
