import SwiftUI
import Combine

struct AppSettings: Codable {
    enum Appearance: String, CaseIterable, Codable {
        case system = "System", light = "Light", dark = "Dark"
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    var appearance: Appearance = .system
    var math = MathConfiguration()
}

@MainActor
final class AppPreferences: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            if let data = try? JSONEncoder().encode(settings) {
                defaults.set(data, forKey: Self.storageKey)
            }
        }
    }
    private let defaults: UserDefaults
    private static let storageKey = "mathgate.settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           var decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            decoded.math = decoded.math.normalized
            settings = decoded
        } else { settings = AppSettings() }
    }
    func setOperation(_ operation: Problem.Operation, enabled: Bool) {
        var config = settings.math
        if enabled { config.operations.insert(operation) }
        else if config.operations.count > 1 { config.operations.remove(operation) }
        settings.math = config.normalized
    }
    func setRange(_ key: WritableKeyPath<MathConfiguration, NumberRange>, value: NumberRange) {
        var config = settings.math
        config[keyPath: key] = value.normalized
        settings.math = config
    }
    func resetMath() { settings.math = MathConfiguration() }
}
