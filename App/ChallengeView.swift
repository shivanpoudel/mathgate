import SwiftUI

// Both entry points share the same typed-answer gate; only the required count differs.
struct ChallengeView: View {
    let disablingBlocking: Bool
    let complete: (TimeInterval) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var challenge: Challenge
    @State private var answer = ""
    @State private var started: Date?
    @FocusState private var focused: Bool

    init(configuration: MathConfiguration, disablingBlocking: Bool,
         complete: @escaping (TimeInterval) -> Void) {
        self.disablingBlocking = disablingBlocking
        self.complete = complete
        _challenge = State(initialValue: Challenge(configuration: configuration,
                                                   disablingBlocking: disablingBlocking))
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Text("MathGate").font(.system(size: 28, weight: .bold, design: .serif))
                    if disablingBlocking {
                        Text("Complete this round to turn off blocking for all selected apps.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("\(challenge.completed) / \(challenge.questions.count) correct")
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
                                if started == nil { started = Date() }
                                await Task.yield()
                                guard !Task.isCancelled else { return }
                                focused = true
                            }
                            .onChange(of: answer) { _, value in
                                guard challenge.submit(value) else { return }
                                answer = ""
                                if challenge.isComplete {
                                    focused = false
                                    complete(Date().timeIntervalSince(started ?? Date()))
                                }
                            }
                        Text("Type the answer. Correct answers advance automatically.")
                            .font(.footnote).foregroundStyle(.secondary)
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
        .interactiveDismissDisabled()
    }
}
