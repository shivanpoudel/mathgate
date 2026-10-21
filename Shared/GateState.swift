import Foundation
import FamilyControls
import ManagedSettings

// Keep this app group identical in all four targets' entitlements.
enum GateState {
    static let group = "group.com.shivanpoudel.mathgate"
    static var defaults: UserDefaults { UserDefaults(suiteName: group)! }
    static let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("mathgate"))
    static var enabled: Bool {
        get { defaults.bool(forKey: "enabled") }
        set { defaults.set(newValue, forKey: "enabled") }
    }
    static var expiry: Date? {
        get { defaults.object(forKey: "expiry") as? Date }
        set { defaults.set(newValue, forKey: "expiry") }
    }
    static var activity: String? {
        get { defaults.string(forKey: "activity") }
        set { defaults.set(newValue, forKey: "activity") }
    }
    static var selection: FamilyActivitySelection {
        guard let data = defaults.data(forKey: "selection"),
              let value = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return value
    }
    static func saveSelection(_ selection: FamilyActivitySelection) throws {
        defaults.set(try JSONEncoder().encode(selection), forKey: "selection")
    }
    static func applyShield() {
        let apps = selection.applicationTokens
        store.shield.applications = apps.isEmpty ? nil : apps
    }
}
