import Foundation
import Combine
#if !PRACTICE
import FamilyControls
import DeviceActivity
import ManagedSettings
#endif

@MainActor
final class Blocker: ObservableObject {
    @Published var error = ""
    @Published var unlockUntil: Date?
    #if PRACTICE
    let isPractice = true
    var status: String { "Ten questions. Typed answers. No distractions." }
    var canStart: Bool { true }
    func refresh() {}
    func lockNow() {}
    func grant() -> Bool { true }
    #else
    let isPractice = false
    @Published var authorized = false
    @Published var enabled = false
    @Published var selection = FamilyActivitySelection()
    var canStart: Bool { authorized && enabled && !selection.applicationTokens.isEmpty }
    var status: String {
        if !authorized { return "Allow Screen Time access to get started." }
        if selection.applicationTokens.isEmpty { return "Choose the apps you want to block." }
        if !enabled { return "Blocking is off." }
        if let unlockUntil, unlockUntil > Date() { return "Access granted." }
        return "Your selected apps are blocked. Solve ten questions to continue."
    }
    init() { refresh() }
    func refresh() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        selection = GateState.selection
        enabled = GateState.enabled
        if GateState.enabled, GateState.expiry == nil || GateState.expiry! <= Date() {
            GateState.applyShield()
            GateState.expiry = nil
        }
        unlockUntil = GateState.expiry
    }
    func authorize() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            error = ""
        } catch { self.error = "Authorization failed: \(error.localizedDescription)" }
        refresh()
    }
    func save(_ chosen: FamilyActivitySelection) {
        // This MVP deliberately supports individual apps, not categories or websites.
        var appsOnly = FamilyActivitySelection()
        appsOnly.applicationTokens = chosen.applicationTokens
        do {
            try GateState.saveSelection(appsOnly)
            lockNow()
            error = chosen.categoryTokens.isEmpty && chosen.webDomainTokens.isEmpty
                ? "" : "Only individual apps were saved. Expand categories and select their apps."
        } catch { self.error = "Could not save apps: \(error.localizedDescription)" }
        refresh()
    }
    func enable() {
        guard authorized, !selection.applicationTokens.isEmpty else { return }
        GateState.enabled = true
        lockNow()
    }
    func disable() {
        GateState.enabled = false
        GateState.activity = nil
        GateState.expiry = nil
        DeviceActivityCenter().stopMonitoring()
        GateState.store.clearAllSettings()
        refresh()
    }
    func lockNow() {
        GateState.activity = nil
        GateState.expiry = nil
        DeviceActivityCenter().stopMonitoring()
        if GateState.enabled { GateState.applyShield() }
        refresh()
    }
    func grant() -> Bool {
        refresh()
        guard canStart else { error = "Enable blocking and select apps first."; return false }
        let center = DeviceActivityCenter()
        center.stopMonitoring()
        let start = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))
        let end = start.addingTimeInterval(15 * 60)
        let activity = "mathgate.unlock.\(UUID().uuidString)"
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: start),
            intervalEnd: calendar.dateComponents(components, from: end), repeats: false)
        GateState.activity = activity
        GateState.expiry = end
        do {
            try center.startMonitoring(DeviceActivityName(activity), during: schedule)
            // Only lift the shield after scheduling succeeded.
            GateState.store.clearAllSettings()
            error = ""
            refresh()
            return true
        } catch {
            GateState.activity = nil
            GateState.expiry = nil
            GateState.applyShield()
            self.error = "Could not schedule reblocking. Apps remain blocked. \(error.localizedDescription)"
            refresh()
            return false
        }
    }
    #endif
}
