import SwiftUI
import Combine
#if !PRACTICE
import FamilyControls
#endif

struct ContentView: View {
    @StateObject private var blocker = Blocker()
    @Environment(\.scenePhase) private var scenePhase
    @State private var challenge = Challenge()
    @State private var answer = ""
    @State private var solving = false
    @State private var message = ""
    @State private var showPicker = false
    @State private var started = Date()
    @State private var elapsed: TimeInterval = 0
    @FocusState private var focused: Bool
    #if !PRACTICE
    @State private var selection = FamilyActivitySelection()
    #endif

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("MathGate").font(.system(size: 28, weight: .bold, design: .serif))
                if solving {
                    Text("\(challenge.completed) / 10 correct").font(.system(.body, design: .monospaced))
                    if let problem = challenge.current {
                        Text(problem.text).font(.system(size: 44, design: .monospaced))
                            .minimumScaleFactor(0.5).lineLimit(1)
                            .accessibilityLabel(problem.text)
                        TextField("answer", text: $answer)
                            .font(.system(size: 32, design: .monospaced))
                            .multilineTextAlignment(.center).keyboardType(.numberPad)
                            .textFieldStyle(.plain).padding(12)
                            .overlay(Rectangle().stroke(.black, lineWidth: 1))
                            .focused($focused).accessibilityLabel("Answer")
                            .onChange(of: answer) { _, value in
                                if challenge.submit(value) {
                                    answer = ""
                                    if challenge.isComplete { finish() }
                                }
                            }
                        Text("Type the answer. Correct answers advance automatically.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Cancel") { solving = false; answer = ""; focused = false }
                    }
                } else {
                    Text(blocker.status).multilineTextAlignment(.center)
                    if let end = blocker.unlockUntil, end > Date() {
                        Text("Access until \(end.formatted(date: .omitted, time: .shortened))")
                        Button("block again now") { blocker.lockNow(); message = "" }
                    } else {
                        Button(blocker.isPractice ? "start practice" : "solve 10 questions") { begin() }
                            .disabled(!blocker.canStart)
                    }
                    if !message.isEmpty { Text(message).multilineTextAlignment(.center) }
                    if !blocker.error.isEmpty { Text(blocker.error).foregroundStyle(.red) }
                    #if !PRACTICE
                    if !blocker.authorized {
                        Button("allow Screen Time access") { Task { await blocker.authorize() } }
                    } else {
                        Button("choose apps") { selection = blocker.selection; showPicker = true }
                        Text("\(blocker.selection.applicationTokens.count) apps selected")
                        if blocker.enabled {
                            Button("turn blocking off") { blocker.disable(); message = "" }
                        } else {
                            Button("turn blocking on") { blocker.enable(); message = "" }
                                .disabled(blocker.selection.applicationTokens.isEmpty)
                        }
                    }
                    Text("10 correct answers unlock all selected apps for 15 minutes. Reopening an app during that window does not require another round.")
                        .font(.footnote).multilineTextAlignment(.center)
                    #else
                    Text("Practice build. This version does not block other apps.")
                        .font(.footnote).multilineTextAlignment(.center)
                    #endif
                }
            }
            .padding(28).frame(maxWidth: 440).frame(maxWidth: .infinity)
        }
        .background(Color.white).foregroundStyle(.black)
        .buttonStyle(PlainBoxStyle())
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { blocker.refresh() }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            if let expiry = blocker.unlockUntil, expiry <= now { blocker.refresh() }
        }
        #if !PRACTICE
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                FamilyActivityPicker(selection: $selection)
                    .navigationTitle("Choose individual apps")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showPicker = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { blocker.save(selection); showPicker = false }
                        }
                    }
            }
        }
        #endif
    }
    private func begin() {
        challenge = Challenge(); answer = ""; message = ""; started = Date()
        solving = true; focused = true
    }
    private func finish() {
        elapsed = Date().timeIntervalSince(started)
        solving = false; focused = false
        if blocker.grant() {
            message = blocker.isPractice
                ? String(format: "10 correct in %.1f seconds.", elapsed)
                : "Complete. Return to the selected app to use your access window."
        }
    }
}

struct PlainBoxStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 16, design: .monospaced))
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(configuration.isPressed ? Color.gray.opacity(0.25) : Color(white: 0.94))
            .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
