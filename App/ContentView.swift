import SwiftUI
import Combine

struct ChallengeSession: Identifiable {
    let id = UUID()
    enum Purpose { case appAccess, disableBlocking, preview, previewDisable }
    let purpose: Purpose
    let configuration: MathConfiguration
}

struct ContentView: View {
    @StateObject private var blocker = Blocker()
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var showPreviewNotice = false
    @State private var previewRequested: ChallengeSession.Purpose?
    @State private var busy = false
    @State private var session: ChallengeSession?
    @State private var message = ""

    private var accessActive: Bool {
        if let end = blocker.unlockUntil { return end > Date() }
        return false
    }
    private var buttonTitle: String {
        if busy { return "Please wait" }
        return blocker.enabled ? "Unblock" : "Block"
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
                        .accessibilityHint(blocker.enabled
                            ? "Complete extra questions to turn blocking off" : "Turns on app blocking")
                        if let end = blocker.unlockUntil, accessActive {
                            Text("Access until \(end.formatted(date: .omitted, time: .shortened))")
                                .font(.footnote)
                            Button("Block again") { blocker.lockNow(); message = "" }
                                .buttonStyle(PlainBoxStyle())
                        }
                        if !message.isEmpty { Text(message).multilineTextAlignment(.center) }
                        if !blocker.error.isEmpty {
                            Text(blocker.error).foregroundStyle(.red).multilineTextAlignment(.center)
                        }
                        if blocker.isPractice {
                            Text("Preview build. Other apps are not blocked.")
                                .font(.footnote).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("\(preferences.settings.math.questionCount) correct answers · 15 minutes of access")
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
        .sheet(isPresented: $showSettings, onDismiss: settingsDismissed) {
            SettingsView(blocker: blocker, previewGate: { disabling in
                previewRequested = disabling ? .previewDisable : .preview
                showSettings = false
            })
                .environmentObject(preferences)
                .preferredColorScheme(preferences.settings.appearance.colorScheme)
        }
        .fullScreenCover(item: $session, onDismiss: consumeShieldRequest) { current in
            ChallengeView(configuration: current.configuration,
                          disablingBlocking: current.purpose == .disableBlocking || current.purpose == .previewDisable) { _ in
                switch current.purpose {
                case .appAccess:
                    message = blocker.grant() ? "Complete. Return to your app to use the access window." : ""
                case .disableBlocking:
                    blocker.disable()
                    message = "Blocking is off. All selected apps are available."
                case .preview, .previewDisable:
                    message = "Gate preview complete. No apps were unlocked."
                }
                session = nil
            }
            .preferredColorScheme(preferences.settings.appearance.colorScheme)
        }
        .alert("Preview build", isPresented: $showPreviewNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can preview the app-opening gate in Settings here. Blocking other apps needs the full MathGate build with Screen Time access on an iPhone.")
        }
        .task { blocker.refresh(); consumeShieldRequest() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { blocker.refresh(); consumeShieldRequest() }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            if let expiry = blocker.unlockUntil, expiry <= now { blocker.refresh() }
        }
    }
    private func start(_ purpose: ChallengeSession.Purpose) {
        message = ""
        session = ChallengeSession(purpose: purpose, configuration: preferences.settings.math)
    }
    private func handleBlockButton() {
        message = ""
        if blocker.isPractice { showPreviewNotice = true; return }
        if blocker.enabled { start(.disableBlocking); return }
        busy = true
        Task { @MainActor in
            defer { busy = false }
            if !blocker.authorized { await blocker.authorize() }
            guard blocker.authorized else { return }
            if blocker.selectedAppCount == 0 { showSettings = true }
            else { blocker.enable() }
        }
    }
    private func settingsDismissed() {
        if let purpose = previewRequested {
            previewRequested = nil
            start(purpose)
        } else { consumeShieldRequest() }
    }
    private func consumeShieldRequest() {
        #if !PRACTICE
        guard !showSettings, session == nil, GateState.challengeRequested else { return }
        GateState.challengeRequested = false
        blocker.refresh()
        if blocker.canStart && !accessActive { start(.appAccess) }
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
