import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    @State private var resetMath = false
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
                    ForEach(Problem.Operation.allCases, id: \.self) { operation in
                        Toggle(operation.title, isOn: Binding(
                            get: { preferences.settings.math.operations.contains(operation) },
                            set: { preferences.setOperation(operation, enabled: $0) }))
                            .disabled(preferences.settings.math.operations.count == 1 &&
                                preferences.settings.math.operations.contains(operation))
                    }
                } header: { Text("Math content") }
                footer: { Text("Keep at least one operation enabled. Each round uses the settings selected before it starts.") }

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
                    NavigationLink("How to practice") {
                        information("How to practice", text: "Choose a time limit on the home screen, then tap Start. Type each answer; correct answers advance automatically and increase your score. Wrong answers stay on the same question. Leaving MathGate, locking your phone, or another interruption ends the round without earning access. When time runs out, your final score appears. Cancel ends a round without a result. Complete a full uninterrupted round with at least one correct answer to earn one Instagram visit through your Shortcuts automations. This is not system-enforced blocking.")
                    }
                    NavigationLink("Connect Instagram") {
                        information("Connect Instagram", text: "Create two Shortcuts automations, both set to Run Immediately. Instagram Is Opened: Check Instagram Access, then If the result is false, Open App MathGate, End If. Instagram Is Closed: End Instagram Visit. Replace your old unconditional Open MathGate action. Complete a round, then return to Instagram yourself. Leaving Instagram resets the visit, including switching to another app. Configure both actions from the same installed MathGate app. Shortcuts can be disabled or delayed; this is a voluntary interruption.")
                    }
                    NavigationLink("Privacy & about") {
                        information("Privacy & about", text: "MathGate generates arithmetic on your device. No account, server, advertising, analytics, or ML model is used. Appearance, math choices, and your Instagram completion pass are saved locally. Challenge results are not kept as a history. MathGate is an independent project inspired by arithmetic speed drills, not affiliated with Zetamac.")
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
            } message: { Text("Restore all four operations and the original number ranges. Appearance and the time limit stay as they are.") }

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
