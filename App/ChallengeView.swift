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
                        Text("Time’s up").font(.system(size: 28, weight: .bold, design: .serif))
                        Text("\(round.score) correct").font(.system(size: 36, design: .monospaced))
                        Text("in \(Int(round.duration)) seconds").foregroundStyle(.secondary)
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
                                guard !Task.isCancelled, !finished else { return }
                                if started == nil { started = ContinuousClock.now }
                                focused = true
                            }
                            .onChange(of: answer) { _, value in
                                guard !finished, started != nil else { return }
                                let time = elapsed
                                if round.remaining(at: time) == 0 { finish(); return }
                                if round.submit(value, elapsed: time) { answer = "" }
                            }
                        Text("Type the answer. Correct answers advance automatically.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Cancel") { focused = false; dismiss() }
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
            if phase == .active {
                updateTime()
                if !finished { focused = true }
            }
        }
    }
    private func updateTime() {
        guard started != nil, !finished else { return }
        secondsLeft = Int(ceil(round.remaining(at: elapsed)))
        if secondsLeft == 0 { finish() }
    }
    private func finish() { finished = true; focused = false; secondsLeft = 0 }
    private func restart() {
        round = TimedPractice(configuration: round.configuration, duration: round.duration)
        answer = ""; secondsLeft = Int(round.duration)
        started = nil; finished = false
    }
}
