import SwiftUI
import Combine

struct ChallengeSession: Identifiable {
    let id = UUID()
    let unlocksApps: Bool
    let configuration: MathConfiguration
}

struct ContentView: View {
    @StateObject private var blocker = Blocker()
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var showPreviewNotice = false
    @State private var confirmDisable = false
    @State private var busy = false
    @State private var session: ChallengeSession?
    @State private var message = ""

    private var accessActive: Bool {
        if let end = blocker.unlockUntil { return end > Date() }
        return false
    }
    private var buttonTitle: String {
        if busy { return "Please wait" }
        if accessActive { return "Block again" }
        return blocker.enabled ? "Blocked" : "Block"
    }
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 26) {
                        Text("MathGate").font(.system(size: 32, weight: .bold, design: .serif))
                        Text(blocker.status).multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button { handleBlockButton() } label: {
                            VStack(spacing: 14) {
                                Image(systemName: blocker.enabled && !accessActive ? "lock.fill" : "power")
                                    .font(.system(size: 38, weight: .regular))
                                Text(buttonTitle).font(.system(size: 24, design: .monospaced))
                            }
                            .frame(width: 180, height: 180)
                            .background(Color(uiColor: .secondarySystemBackground), in: Circle())
                            .overlay(Circle().stroke(Color.primary, lineWidth: 1))
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain).disabled(busy)
                        .accessibilityLabel(buttonTitle)
                        .accessibilityHint(blocker.enabled && !accessActive
                            ? "Opens the option to turn blocking off" : "Turns on app blocking")
                        if let end = blocker.unlockUntil, accessActive {
                            Text("Access until \(end.formatted(date: .omitted, time: .shortened))")
                                .font(.footnote)
                        }
                        if blocker.enabled && !accessActive && blocker.canStart {
                            Button("Solve to unlock") { start(unlocksApps: true) }
                                .buttonStyle(PlainBoxStyle())
                        }
                        Button("Practice math") { start(unlocksApps: false) }
                            .buttonStyle(PlainBoxStyle())
                        if !message.isEmpty { Text(message).multilineTextAlignment(.center) }
                        if !blocker.error.isEmpty {
                            Text(blocker.error).foregroundStyle(.red).multilineTextAlignment(.center)
                        }
                        if blocker.isPractice {
                            Text("Preview build. Other apps are not blocked.")
                                .font(.footnote).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("10 correct answers · 15 minutes of access")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(28).frame(maxWidth: 440)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .center)
                }
            }
            .background(Color(uiColor: .systemBackground))
            .foregroundStyle(.primary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .tint(.primary)
        .sheet(isPresented: $showSettings, onDismiss: consumeShieldRequest) {
            SettingsView(blocker: blocker)
                .environmentObject(preferences)
                .preferredColorScheme(preferences.settings.appearance.colorScheme)
        }
        .fullScreenCover(item: $session, onDismiss: consumeShieldRequest) { current in
            ChallengeView(configuration: current.configuration, unlocksApps: current.unlocksApps) { elapsed in
                if current.unlocksApps {
                    message = blocker.grant() ? "Complete. Return to your app to use the access window." : ""
                } else { message = String(format: "10 correct in %.1f seconds.", elapsed) }
                session = nil
            }
            .preferredColorScheme(preferences.settings.appearance.colorScheme)
        }
        .alert("Preview build", isPresented: $showPreviewNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can try settings and practice here. Blocking other apps needs the full MathGate build with Screen Time access on an iPhone.")
        }
        .confirmationDialog("Turn off blocking?", isPresented: $confirmDisable, titleVisibility: .visible) {
            Button("Turn off blocking", role: .destructive) { blocker.disable(); message = "" }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Your selected apps will be available without completing a challenge.") }
        .task { blocker.refresh(); consumeShieldRequest() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { blocker.refresh(); consumeShieldRequest() }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            if let expiry = blocker.unlockUntil, expiry <= now { blocker.refresh() }
        }
    }
    private func start(unlocksApps: Bool) {
        message = ""
        session = ChallengeSession(unlocksApps: unlocksApps, configuration: preferences.settings.math)
    }
    private func handleBlockButton() {
        message = ""
        if blocker.isPractice { showPreviewNotice = true; return }
        if accessActive { blocker.lockNow(); return }
        if blocker.enabled { confirmDisable = true; return }
        busy = true
        Task { @MainActor in
            defer { busy = false }
            if !blocker.authorized { await blocker.authorize() }
            guard blocker.authorized else { return }
            if blocker.selectedAppCount == 0 { showSettings = true }
            else { blocker.enable() }
        }
    }
    private func consumeShieldRequest() {
        #if !PRACTICE
        guard !showSettings, session == nil, GateState.challengeRequested else { return }
        GateState.challengeRequested = false
        blocker.refresh()
        if blocker.canStart && !accessActive { start(unlocksApps: true) }
        #endif
    }
}

struct PlainBoxStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 16, design: .monospaced))
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemBackground))
            .overlay(Rectangle().stroke(Color.primary, lineWidth: 1))
            .opacity(!isEnabled ? 0.4 : (configuration.isPressed ? 0.7 : 1))
    }
}
