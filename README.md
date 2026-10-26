# MathGate

Plain, Zetamac-inspired timed arithmetic for iPhone. Pick 30–300 seconds in 15-second steps on the home screen (default 60), then tap Start. Type answers with the numeric keyboard. Correct answers advance automatically and increase the score; wrong answers stay on the same question. There is no question-count limit. When time expires, the final score appears with Try again and Done. Cancel discards the round and does not earn access. Completing a full uninterrupted round with at least one correct answer earns one hour of Instagram access when the opening automation below is configured.

Settings retain System/Light/Dark appearance, operation selection, and operand ranges. Division has whole-number answers and subtraction has positive answers. Preferences persist locally. The time limit persists separately and is not changed by Reset math settings. Existing appearance and math preferences remain compatible with previous builds. Each round snapshots its settings.

The timer uses a continuous monotonic clock. A round is interrupted without earning a pass as soon as MathGate becomes inactive, including switching apps, locking the phone, or opening system UI that interrupts the app. A zero-score round does not earn a pass. Answers arriving at or after the deadline are rejected. Wait for the completion message before returning to Instagram. Try again starts a new round. Starting, cancelling, or interrupting extra practice does not erase an existing hourly pass. Completing another qualifying round starts a fresh hour.

## Install on your iPhone without paid membership

Pull the latest repository changes, open `MathGate.xcodeproj`, and select the **MathGate** scheme. Connect and unlock your iPhone, trust the Mac if prompted, and select the phone as Xcode's run destination. Sign in under Xcode Settings > Apple Accounts. Select the MathGate target, open Signing & Capabilities, enable automatic signing, and select your Personal Team. Enable Developer Mode on the iPhone when requested, then press Command-R.

Both MathGate and the compatibility MathGatePractice scheme now build only the timed-practice app. Neither includes Screen Time extensions, Family Controls, or App Group entitlements. The compatibility scheme keeps its old bundle identifier so existing practice settings can be retained. Both apps display as MathGate; if you have both installed, remove the unwanted one to avoid confusing Shortcuts.

Free Personal Team provisioning expires after seven days. Rebuild and reinstall from Xcode when necessary. No paid membership is needed for this version. Your Xcode version must support your phone's iOS version. If Xcode reports a bundle identifier is unavailable, choose a unique identifier for the selected target. Project signing-team choices are local to your setup.

## Connect Instagram with Shortcuts

Install the update and launch MathGate once. Keep **Instagram > Is Opened > Run Immediately** with these actions:

1. **Check Instagram Access**, found under MathGate's actions.
2. **If** the result **is false** (No), **Open App > MathGate**.
3. **End If**. Otherwise, do nothing. Do not add Open Instagram; it is already open.

**Disable or delete the Instagram Is Closed automation.** The existing End Instagram Visit action remains available as a no-op for compatibility, so forgetting to remove that automation will not reset your pass.

Complete an uninterrupted timed round of at least 30 seconds with at least one correct answer. A pass expires exactly one hour after completion: finishing at 2:17 grants access until 3:17. During that hour, opening, closing, switching away, and returning to Instagram do not require more math and do not extend the deadline. Once expired, the next opening redirects to MathGate. Instagram is not forcibly interrupted if already onscreen at expiry. Cancelled, interrupted, unfinished, and zero-score rounds do not grant or extend access.

The old 15-second duration preference is raised to 30 seconds. The default remains 60 seconds. Existing appearance and math settings are preserved. Old single-visit passes migrate to no access because they have no completion timestamp; complete one new round after updating.

Pass timestamps persist locally across process restarts. The expiry uses the device clock, so manually changing it is outside the enforcement guarantees. There is no background timer or Screen Time entitlement. Shortcuts can still be disabled or delayed. Configure Check Instagram Access and Open App from the same installed MathGate build; MathGatePractice has separate storage. This version is configured for Instagram only.

## Validation

This revision was source-reviewed and the generated project checked structurally. It has not been compiled or run here because the delivery environment lacks Swift and Xcode. On your Mac, run `swift test` for arithmetic, configurable gate legacy tests, timed-round deadline/scoring tests, and completion-pass lifecycle/persistence tests. Build with Command-R and check the numeric keyboard, timer expiry, Cancel, Try again, settings persistence, and interruption on leaving or locking the phone. Verify no pass for Cancel, zero score, or interruption; repeated visits during the earned hour; continued access after leaving Instagram; and a new challenge on the first opening after expiry. Test the phone installation and Shortcuts automation separately.

## Source layout and preserved work

`App/ContentView.swift` is the home screen and duration picker. `App/ChallengeView.swift` runs timed practice and shows results. `App/SettingsView.swift` and `App/Preferences.swift` manage local settings. `Core/Arithmetic.swift` contains arithmetic generation and the timed-round model. `Core/CompletionPass.swift` owns the pass lifecycle; `App/ShortcutActions.swift` stores it and exposes the two App Intents. No server, analytics, account, or ML model is used.

The previous Screen Time sources remain in `App/Blocker.swift`, `Shared`, `Action`, `Monitor`, and `Shield` for future reference, but are not compiled into either app. The last blocking implementation is also preserved in Git history at commit `297a7122ab3fa19c230dfa6142357f90e1a0604b`. This revision deliberately removes the blocking targets and their signing requirements from the Xcode project.

`scripts/generate_project.py` regenerates the project and overwrites local project/signing changes; do not rerun it casually after configuring your team. No extra dependency manager is required. Edit Swift source in VS Code and use Xcode to install and debug.

Apple references: [free development accounts](https://developer.apple.com/help/account/basics/about-your-developer-account/), [running on a device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), [Shortcuts app triggers](https://support.apple.com/guide/shortcuts/setting-triggers-apde31e9638b/ios).
