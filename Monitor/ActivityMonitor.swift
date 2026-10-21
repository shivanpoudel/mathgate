import DeviceActivity

final class ActivityMonitor: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Ignore callbacks from cancelled or superseded access windows.
        guard GateState.enabled, GateState.activity == activity.rawValue else { return }
        GateState.applyShield()
        GateState.expiry = nil
        GateState.activity = nil
    }
}
