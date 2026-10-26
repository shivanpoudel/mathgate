import SwiftUI
import Combine

struct ChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var round: TimedPractice
    @State private var answer = ""
    @State private var started: ContinuousClock.Instant?
    @State private var secondsLeft: Int
    @State private var finished = false
    @State private var interrupted = false
    @State private var earnedPass = false
    @FocusState private var focused: Bool

    init(configuration: MathConfiguration, duration: Int) {
        let round = TimedPractice(configuration: configuration, duration: TimeInterval(duration))
        _round = State(initialValue: round)
        _secondsLeft = State(initialValue: Int(round.duration))
    }
    private var elapsed: TimeInterval {
        guard let started else { return 0 }
        let components = started.duration(to: ContinuousClock.now).components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    if finished {
                        Text(interrupted ? "Round interrupted" : "Time’s up").font(.system(size: 28, weight: .bold, design: .serif))
                        Text("\(round.score) correct").font(.system(size: 36, design: .monospaced))
                        if !interrupted {
                            Text("in \(Int(round.duration)) seconds").foregroundStyle(.secondary)
                        }
                        Text(earnedPass
                             ? "Round complete. Instagram access is available for one hour."
                             : (interrupted ? "Stay in MathGate for the full round to earn access." : "Answer at least one question correctly to earn access."))
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Try again") { restart() }
                        Button("Done") { dismiss() }
                    } else {
                        Text("\(secondsLeft)s remaining · \(round.score) correct")
                            .font(.system(.body, design: .monospaced))
                            .monospacedDigit()
                        Text(round.current.text).font(.system(size: 44, design: .monospaced))
                            .minimumScaleFactor(0.5).lineLimit(1)
                        TextField("answer", text: $answer)
                            .font(.system(size: 32, design: .monospaced))
                            .multilineTextAlignment(.center).keyboardType(.numberPad)
                            .textFieldStyle(.plain).padding(12)
                            .overlay(Rectangle().stroke(Color.primary, lineWidth: 1))
                            .focused($focused).accessibilityLabel("Answer")
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                            .task {
                                await Task.yield()
                                guard !Task.isCancelled, !finished, scenePhase == .active else { return }
                                if started == nil {
                                    CompletionPassStore.shared.beginRound()
                                    started = ContinuousClock.now
                                }
                                focused = true
                            }
                            .onChange(of: answer) { _, value in
                                guard !finished, started != nil, scenePhase == .active else { return }
                                let time = elapsed
                                if round.remaining(at: time) == 0 { finish(); return }
                                if round.submit(value, elapsed: time) { answer = "" }
                            }
                        Text("Type the answer. Correct answers advance automatically.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Cancel") { CompletionPassStore.shared.beginRound(); focused = false; dismiss() }
                    }
                }
                .multilineTextAlignment(.center)
                .padding(28).frame(maxWidth: 440)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollDismissesKeyboard(.never)
        }
        .background(Color(uiColor: .systemBackground)).foregroundStyle(.primary)
        .buttonStyle(PlainBoxStyle()).interactiveDismissDisabled()
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in updateTime() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, started != nil, !finished {
                // Invalidate immediately, even if the UI timer has not delivered its final tick.
                interrupted = true
                earnedPass = false
                finished = true
                focused = false
                CompletionPassStore.shared.beginRound()
            } else if phase == .active {
                if started == nil, !finished {
                    CompletionPassStore.shared.beginRound()
                    started = ContinuousClock.now
                }
                updateTime()
                if !finished { focused = true }
            }
        }
    }
    private func updateTime() {
        guard started != nil, !finished, scenePhase == .active else { return }
        secondsLeft = Int(ceil(round.remaining(at: elapsed)))
        if secondsLeft == 0 { finish() }
    }
    private func finish() {
        guard !finished else { return }
        earnedPass = !interrupted && scenePhase == .active && round.score > 0
        CompletionPassStore.shared.finishRound(timeExpired: round.remaining(at: elapsed) == 0,
                                               score: round.score, interrupted: !earnedPass, duration: round.duration)
        finished = true; focused = false; secondsLeft = 0
    }
    private func restart() {
        round = TimedPractice(configuration: round.configuration, duration: round.duration)
        answer = ""; secondsLeft = Int(round.duration)
        CompletionPassStore.shared.beginRound()
        started = nil; finished = false; interrupted = false; earnedPass = false
    }
}
