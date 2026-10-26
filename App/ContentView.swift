import SwiftUI

struct PracticeSession: Identifiable {
    let id = UUID()
    let duration: Int
    let configuration: MathConfiguration
}

struct ContentView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @AppStorage("mathgate.duration.seconds") private var duration = 60
    @State private var showSettings = false
    @State private var session: PracticeSession?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        Text("MathGate").font(.system(size: 32, weight: .bold, design: .serif))
                        Text("Solve as many as you can before time runs out.")
                            .foregroundStyle(.secondary)
                        Text("Complete a round to earn one hour of Instagram access.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Picker("Time limit", selection: $duration) {
                            ForEach(2...20, id: \.self) { step in
                                Text("\(step * 15) seconds").tag(step * 15)
                            }
                        }
                        .pickerStyle(.wheel).frame(height: 140)
                        .accessibilityLabel("Time limit in seconds")
                        Button("Start") {
                            session = PracticeSession(duration: duration, configuration: preferences.settings.math)
                        }
                        .buttonStyle(PlainBoxStyle())
                    }
                    .multilineTextAlignment(.center)
                    .padding(28).frame(maxWidth: 440)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").frame(width: 44, height: 44)
                    }.accessibilityLabel("Settings")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .tint(.primary)
        .onAppear {
            if duration == 15 { duration = 30 }
            else if !(30...300).contains(duration) || duration % 15 != 0 { duration = 60 }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(preferences)
                .preferredColorScheme(preferences.settings.appearance.colorScheme)
        }
        .fullScreenCover(item: $session) { current in
            ChallengeView(configuration: current.configuration, duration: current.duration)
                .preferredColorScheme(preferences.settings.appearance.colorScheme)
        }
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
