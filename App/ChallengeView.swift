import SwiftUI

// The same ten-question interaction serves both practice and real unlocks.
struct ChallengeView: View {
    let configuration: MathConfiguration
    let unlocksApps: Bool
    let complete: (TimeInterval) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var challenge: Challenge
    @State private var answer = ""
    @State private var solving = false
    @State private var started = Date()
    @FocusState private var focused: Bool

    init(configuration: MathConfiguration, unlocksApps: Bool,
         complete: @escaping (TimeInterval) -> Void) {
        self.configuration = configuration
        self.unlocksApps = unlocksApps
        self.complete = complete
        _challenge = State(initialValue: Challenge(configuration: configuration))
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Text("MathGate").font(.system(size: 28, weight: .bold, design: .serif))
                    if solving {
                        Text("\(challenge.completed) / 10 correct")
                            .font(.system(.body, design: .monospaced))
                        if let problem = challenge.current {
                            Text(problem.text).font(.system(size: 44, design: .monospaced))
                                .minimumScaleFactor(0.5).lineLimit(1)
                                .accessibilityLabel(problem.text)
                            TextField("answer", text: $answer)
                                .font(.system(size: 32, design: .monospaced))
                                .multilineTextAlignment(.center).keyboardType(.numberPad)
                                .textFieldStyle(.plain).padding(12)
                                .overlay(Rectangle().stroke(Color.primary, lineWidth: 1))
                                .focused($focused).accessibilityLabel("Answer")
                                .autocorrectionDisabled().textInputAutocapitalization(.never)
                                .task {
                                    await Task.yield()
                                    guard !Task.isCancelled, solving else { return }
                                    focused = true
                                }
                                .onChange(of: answer) { _, value in
                                    guard solving, challenge.submit(value) else { return }
                                    answer = ""
                                    if challenge.isComplete {
                                        solving = false; focused = false
                                        complete(Date().timeIntervalSince(started))
                                    }
                                }
                            Text("Type the answer. Correct answers advance automatically.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Ten questions. Typed answers. No distractions.")
                            .multilineTextAlignment(.center)
                        Button(unlocksApps ? "solve 10 questions" : "start practice") {
                            challenge = Challenge(configuration: configuration)
                            answer = ""; started = Date(); focused = false; solving = true
                        }
                        if !unlocksApps {
                            Text("Practice does not unlock blocked apps.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Button("Cancel") { focused = false; dismiss() }
                }
                .multilineTextAlignment(.center)
                .padding(28).frame(maxWidth: 440)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .center)
            }
            .scrollDismissesKeyboard(.never)
        }
        .background(Color(uiColor: .systemBackground))
        .foregroundStyle(.primary)
        .buttonStyle(PlainBoxStyle())
        .interactiveDismissDisabled(solving)
    }
}
