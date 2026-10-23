# MathGate

Plain, Zetamac-inspired timed arithmetic for iPhone. Pick 15–300 seconds in 15-second steps on the home screen (default 60), then tap Start. Type answers with the numeric keyboard. Correct answers advance automatically and increase the score; wrong answers stay on the same question. There is no question-count limit. When time expires, the final score appears with Try again and Done. Cancel discards the round.

Settings retain System/Light/Dark appearance, operation selection, and operand ranges. Division has whole-number answers and subtraction has positive answers. Preferences persist locally. The time limit persists separately and is not changed by Reset math settings. Existing appearance and math preferences remain compatible with previous builds. Each round snapshots its settings.

The timer uses a continuous monotonic clock and keeps counting while the app is backgrounded or the phone sleeps. Returning after the deadline shows the final score. Answers arriving at or after the deadline are rejected even if a UI timer callback has not fired yet.

## Install on your iPhone without paid membership

Pull the latest repository changes, open `MathGate.xcodeproj`, and select the **MathGate** scheme. Connect and unlock your iPhone, trust the Mac if prompted, and select the phone as Xcode's run destination. Sign in under Xcode Settings > Apple Accounts. Select the MathGate target, open Signing & Capabilities, enable automatic signing, and select your Personal Team. Enable Developer Mode on the iPhone when requested, then press Command-R.

Both MathGate and the compatibility MathGatePractice scheme now build only the timed-practice app. Neither includes Screen Time extensions, Family Controls, or App Group entitlements. The compatibility scheme keeps its old bundle identifier so existing practice settings can be retained. Both apps display as MathGate; if you have both installed, remove the unwanted one to avoid confusing Shortcuts.

Free Personal Team provisioning expires after seven days. Rebuild and reinstall from Xcode when necessary. No paid membership is needed for this version. Your Xcode version must support your phone's iOS version. If Xcode reports a bundle identifier is unavailable, choose a unique identifier for the selected target. Project signing-team choices are local to your setup.

## Try the Shortcuts interruption

After installing, use Apple's Shortcuts app to create an App automation for Instagram, triggered when it Is Opened. Choose Run Immediately where available and add Open App > MathGate. This opens MathGate's home screen; tap Start to begin the selected timed round. If the Shortcuts interface differs on your iOS release, locate the equivalent App-opening trigger and Open App action.

This is an interruption, not enforced blocking. You can dismiss MathGate or disable the automation. The current app does not track which app launched it, automatically return to Instagram, or issue an access pass after completion. Returning to Instagram can trigger the automation again, so this initial experiment is for evaluating the interruption, not a complete unlock workflow.

## Validation

This revision was source-reviewed and the generated project checked structurally. It has not been compiled or run here because the delivery environment lacks Swift and Xcode. On your Mac, run `swift test` for arithmetic, configurable gate legacy tests, and timed-round deadline/scoring tests. Build with Command-R and check the numeric keyboard, timer expiry, Cancel, Try again, settings persistence, and background/foreground expiry. Test the phone installation and Shortcuts automation separately.

## Source layout and preserved work

`App/ContentView.swift` is the home screen and duration picker. `App/ChallengeView.swift` runs timed practice and shows results. `App/SettingsView.swift` and `App/Preferences.swift` manage local settings. `Core/Arithmetic.swift` contains arithmetic generation and the timed-round model. No server, analytics, account, or ML model is used.

The previous Screen Time sources remain in `App/Blocker.swift`, `Shared`, `Action`, `Monitor`, and `Shield` for future reference, but are not compiled into either app. The last blocking implementation is also preserved in Git history at commit `297a7122ab3fa19c230dfa6142357f90e1a0604b`. This revision deliberately removes the blocking targets and their signing requirements from the Xcode project.

`scripts/generate_project.py` regenerates the project and overwrites local project/signing changes; do not rerun it casually after configuring your team. No extra dependency manager is required. Edit Swift source in VS Code and use Xcode to install and debug.

Apple references: [free development accounts](https://developer.apple.com/help/account/basics/about-your-developer-account/), [running on a device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), [Shortcuts app triggers](https://support.apple.com/guide/shortcuts/setting-triggers-apde31e9638b/ios).
