import SwiftUI
#if !PRACTICE
import FamilyControls
#endif

struct SettingsView: View {
    @ObservedObject var blocker: Blocker
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    @State private var resetMath = false
    @State private var authorizing = false
    #if !PRACTICE
    @State private var showPicker = false
    @State private var selection = FamilyActivitySelection()
    #endif

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color mode", selection: $preferences.settings.appearance) {
                        ForEach(AppSettings.Appearance.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                Section {
                    if blocker.isPractice {
                        Text("App selection is available in the full MathGate build on your iPhone.")
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Screen Time", value: blocker.authorized ? "Allowed" : "Not allowed")
                        #if !PRACTICE
                        if blocker.authorized {
                            Button("Choose apps (\(blocker.selectedAppCount) selected)") {
                                selection = blocker.selection; showPicker = true
                            }
                        } else {
                            Button(authorizing ? "Requesting access…" : "Allow Screen Time access") {
                                authorizing = true
                                Task { @MainActor in
                                    await blocker.authorize()
                                    authorizing = false
                                }
                            }
                            .disabled(authorizing)
                        }
                        #endif
                    }
                    if !blocker.error.isEmpty { Text(blocker.error).foregroundStyle(.red) }
                } header: { Text("Blocked apps") }
                footer: { Text("Select individual apps, then use the Block button on the home screen. Changing the selection ends any current access window.") }

                Section {
                    ForEach(Problem.Operation.allCases, id: \.self) { operation in
                        Toggle(operation.title, isOn: Binding(
                            get: { preferences.settings.math.operations.contains(operation) },
                            set: { preferences.setOperation(operation, enabled: $0) }))
                            .disabled(preferences.settings.math.operations.count == 1 &&
                                preferences.settings.math.operations.contains(operation))
                    }
                } header: { Text("Math content") }
                footer: { Text("Keep at least one operation enabled. Each round contains 10 questions and uses the settings selected before it starts.") }

                Section {
                    rangeControls("Numbers", key: \.addition)
                } header: { Text("Addition & subtraction") }
                footer: { Text("Addition draws both numbers from this range. Subtraction reverses those sums, so answers stay positive.") }

                Section {
                    rangeControls("First factor", key: \.firstFactor)
                    rangeControls("Second factor", key: \.secondFactor)
                } header: { Text("Multiplication & division") }
                footer: { Text("Division reverses generated multiplication problems, so answers are always whole numbers. Supported numbers: 1–999.") }

                Section("General") {
                    LabeledContent("Questions per unlock", value: "10")
                    LabeledContent("Access window", value: "15 minutes")
                    NavigationLink("How blocking works") {
                        information("How blocking works", text: "Select apps in Settings and tap Block on the home screen. When you open a blocked app, choose Solve questions. Complete ten correct answers to unlock all selected apps for 15 minutes. Wrong answers stay on the same question; Cancel leaves restrictions in place. Reopening an app during its access window does not require another round. You can block again early or turn blocking off from the home screen. This is a voluntary focus tool; Screen Time access can also be revoked in iOS Settings.")
                    }
                    NavigationLink("Privacy & about") {
                        information("Privacy & about", text: "MathGate generates arithmetic on your device. No account, server, advertising, analytics, or ML model is used. Appearance and math choices are saved locally. The blocking build also stores selected app tokens and access-window state in a local App Group shared with its extensions. Practice results are displayed for the current session, not kept as a history. MathGate is an independent project inspired by arithmetic speed drills, not affiliated with Zetamac.")
                    }
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    Button("Reset math settings", role: .destructive) { resetMath = true }
                }
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("Reset math settings?", isPresented: $resetMath) {
                Button("Reset", role: .destructive) { preferences.resetMath() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Restore all four operations and the original number ranges. Appearance and blocked apps stay as they are.") }
            #if !PRACTICE
            .sheet(isPresented: $showPicker) {
                NavigationStack {
                    FamilyActivityPicker(selection: $selection)
                        .navigationTitle("Choose individual apps")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showPicker = false } }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") { blocker.save(selection); showPicker = false }
                            }
                        }
                }
                .preferredColorScheme(preferences.settings.appearance.colorScheme)
            }
            #endif
        }
    }
    private func rangeControls(_ title: String, key: WritableKeyPath<MathConfiguration, NumberRange>) -> some View {
        let range = preferences.settings.math[keyPath: key]
        return VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Stepper("Minimum: \(range.lower)", value: Binding(
                get: { preferences.settings.math[keyPath: key].lower },
                set: { value in
                    var updated = preferences.settings.math[keyPath: key]
                    updated.lower = value
                    preferences.setRange(key, value: updated)
                }), in: 1...999)
            Stepper("Maximum: \(range.upper)", value: Binding(
                get: { preferences.settings.math[keyPath: key].upper },
                set: { value in
                    var updated = preferences.settings.math[keyPath: key]
                    updated.upper = value
                    preferences.setRange(key, value: updated)
                }), in: range.lower...999)
        }.padding(.vertical, 4)
    }
    private func information(_ title: String, text: String) -> some View {
        ScrollView { Text(text).frame(maxWidth: .infinity, alignment: .leading).padding(24) }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}
