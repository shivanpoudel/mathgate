# MathGate

Plain, Zetamac-inspired timed arithmetic for iPhone. Pick 15–300 seconds in 15-second steps on the home screen (default 60), then tap Start. Type answers with the numeric keyboard. Correct answers advance automatically and increase the score; wrong answers stay on the same question. There is no question-count limit. When time expires, the final score appears with Try again and Done. Cancel discards the round and does not earn access. Completing a full uninterrupted round with at least one correct answer earns one Instagram visit when the two Shortcuts automations below are configured.

Settings retain System/Light/Dark appearance, operation selection, and operand ranges. Division has whole-number answers and subtraction has positive answers. Preferences persist locally. The time limit persists separately and is not changed by Reset math settings. Existing appearance and math preferences remain compatible with previous builds. Each round snapshots its settings.

The timer uses a continuous monotonic clock. A round is interrupted without earning a pass as soon as MathGate becomes inactive, including switching apps, locking the phone, or opening system UI that interrupts the app. A zero-score round does not earn a pass. Answers arriving at or after the deadline are rejected. Wait for the completion message before returning to Instagram. Try again clears any previously earned pass and starts a new round.

## Install on your iPhone without paid membership

Pull the latest repository changes, open `MathGate.xcodeproj`, and select the **MathGate** scheme. Connect and unlock your iPhone, trust the Mac if prompted, and select the phone as Xcode's run destination. Sign in under Xcode Settings > Apple Accounts. Select the MathGate target, open Signing & Capabilities, enable automatic signing, and select your Personal Team. Enable Developer Mode on the iPhone when requested, then press Command-R.

Both MathGate and the compatibility MathGatePractice scheme now build only the timed-practice app. Neither includes Screen Time extensions, Family Controls, or App Group entitlements. The compatibility scheme keeps its old bundle identifier so existing practice settings can be retained. Both apps display as MathGate; if you have both installed, remove the unwanted one to avoid confusing Shortcuts.

Free Personal Team provisioning expires after seven days. Rebuild and reinstall from Xcode when necessary. No paid membership is needed for this version. Your Xcode version must support your phone's iOS version. If Xcode reports a bundle identifier is unavailable, choose a unique identifier for the selected target. Project signing-team choices are local to your setup.

## Connect Instagram with Shortcuts

Install the update and launch MathGate once. There are now two native Shortcuts actions, **Check Instagram Access** and **End Instagram Visit**. They run in the background without opening MathGate and use the app's local preferences. No paid entitlement, App Group, or separate extension is needed. Only Instagram is supported by this initial pass; do not reuse these actions for a second app.

Replace the old unconditional Open MathGate automation. Configure **Instagram > Is Opened > Run Immediately** with these actions in order:

1. **Check Instagram Access**, found by searching actions or under Apps > MathGate.
2. **If** the result from that action **is false** (the Boolean may be displayed as No).
3. Inside the If branch, **Open App > MathGate**.
4. **End If**. The true/Otherwise branch does nothing. Do not add Open Instagram here; it is already open.

Add a second automation: **Instagram > Is Closed > Run Immediately**. Its only action is **End Instagram Visit** from the same MathGate installation. Do not add Open App, Wait, or a completion-grant action. If prompted, authorize these actions while setting up and rerun the test.

Open Instagram. With no pass, the first automation redirects to MathGate. Choose a duration and tap Start. Cancelling, leaving the app, or waiting out the timer with zero correct answers does not grant a pass. Finish the full timer with at least one correct answer, wait for the success message, and return to Instagram manually. The access check activates your earned visit and leaves Instagram open. Leaving Instagram clears the active visit; returning requires a new round.

An unused earned pass survives a close notification from the initial redirect. Once activated, it remains valid until End Instagram Visit runs. No Shortcuts action can directly grant a pass. Starting another round revokes the previous pass. Pass state persists across app process restarts; incomplete rounds do not persist or grant access.

Apple's Is Closed trigger means leaving or switching away from Instagram, not specifically force-quitting or unloading it. Both automations must be enabled. This remains voluntary automation, not a Screen Time shield: disabling/editing automations bypasses it, and iOS may delay, reorder, or fail to run actions. In particular, a missed close action can leave a visit active; a delayed close can invalidate a new visit. Test rapid app switching and locking on your phone before relying on this behavior. Completing a round is a timed participation check (at least one correct answer), not proof of continuous solving or attention.

If actions are missing, ensure the new build is installed, launch MathGate, then reopen Shortcuts. If both MathGate and MathGatePractice are installed, remove the unused one or ensure every action and Open App selection points to the same installation. They have separate local pass storage.

## Validation

This revision was source-reviewed and the generated project checked structurally. It has not been compiled or run here because the delivery environment lacks Swift and Xcode. On your Mac, run `swift test` for arithmetic, configurable gate legacy tests, timed-round deadline/scoring tests, and completion-pass lifecycle/persistence tests. Build with Command-R and check the numeric keyboard, timer expiry, Cancel, Try again, settings persistence, and interruption on leaving or locking the phone. Verify no pass for Cancel, zero score, or interruption; one successful visit after completion; reset after leaving Instagram; and no redirect loop on the successful return. Test the phone installation and Shortcuts automation separately.

## Source layout and preserved work

`App/ContentView.swift` is the home screen and duration picker. `App/ChallengeView.swift` runs timed practice and shows results. `App/SettingsView.swift` and `App/Preferences.swift` manage local settings. `Core/Arithmetic.swift` contains arithmetic generation and the timed-round model. `Core/CompletionPass.swift` owns the pass lifecycle; `App/ShortcutActions.swift` stores it and exposes the two App Intents. No server, analytics, account, or ML model is used.

The previous Screen Time sources remain in `App/Blocker.swift`, `Shared`, `Action`, `Monitor`, and `Shield` for future reference, but are not compiled into either app. The last blocking implementation is also preserved in Git history at commit `297a7122ab3fa19c230dfa6142357f90e1a0604b`. This revision deliberately removes the blocking targets and their signing requirements from the Xcode project.

`scripts/generate_project.py` regenerates the project and overwrites local project/signing changes; do not rerun it casually after configuring your team. No extra dependency manager is required. Edit Swift source in VS Code and use Xcode to install and debug.

Apple references: [free development accounts](https://developer.apple.com/help/account/basics/about-your-developer-account/), [running on a device](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices), [Shortcuts app triggers](https://support.apple.com/guide/shortcuts/setting-triggers-apde31e9638b/ios).
