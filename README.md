# AltTab

A minimal Windows-style window switcher for macOS 14+.

- Hold Option, press Tab to open the switcher and step forward.
- Release Option to focus the selected window.
- A quick tap (less than 150 ms) switches to the previous window and shows no panel.
- One item per window, in most-recently-used order, current Space only.
- The panel shows a vertical list. Each row shows the app icon, the window title and the app name.
- No minimized windows, no windows of hidden apps.
- The system Cmd+Tab does not change.

The app has no visible icon. It starts at login.

## Build and install

1. Create the signing certificate one time (see below).
2. Run `make install`. The app goes to `~/Applications/AltTab.app`.
3. Run `make run`.
4. Give the Accessibility permission when macOS asks (System Settings → Privacy & Security → Accessibility).
   The app starts the key listener within one second after you give the permission.

Other targets:

| Target       | Action                                    |
|--------------|-------------------------------------------|
| `make test`  | Run the `SwitcherState` tests             |
| `make stop`  | Stop the running app                      |
| `make clean` | Remove the build output and `AltTab.app`  |

## Signing certificate

macOS keeps the Accessibility permission only while the code signature stays the same.
An ad-hoc signature changes at each build, so macOS asks for the permission again after each rebuild.
A self-signed certificate gives a stable signature.

1. Open Keychain Access.
2. Select Keychain Access → Certificate Assistant → Create a Certificate.
3. Set Name to `AltTab Dev`.
4. Set Identity Type to `Self Signed Root`.
5. Set Certificate Type to `Code Signing`.
6. Click Create.

If the certificate does not exist, `make` uses an ad-hoc signature and shows a warning.
To use a different certificate name, run `make install IDENTITY="My Name"`.

If you rebuild with a new signature, remove the old AltTab entry from the Accessibility list. Then give the permission again.

## Logs

```sh
log stream --level debug --predicate 'subsystem == "com.dvemar.alttab"'
```

## Login item

At the first start, the app registers itself as a login item.
To remove it, go to System Settings → General → Login Items & Extensions.

## Karabiner-Elements

Karabiner-Elements is not necessary. Without it, use Option+Tab.

With Karabiner-Elements, the app sees the keys after Karabiner remaps them.
Thus the hotkey is the physical key that sends Option in your configuration, plus Tab.

Example: a configuration that gives a Mac a PC-style key layout.

- Built-in Mac keyboard: the physical Command key sends Option. Use physical Command+Tab.
- External PC keyboard: the physical Alt key sends Option. Use physical Alt+Tab.

If a Karabiner rule changes Tab or Option+Tab, the hotkey can stop working.

## Limits

- Secure input (password fields, "Secure Keyboard Entry" in terminals) blocks the event tap.
  Option+Tab does not operate while secure input is on.
- If two windows of one app have the same frame, their order in the list can be wrong.
- Option+Tab with Command or Control is not used, so other shortcuts stay unchanged.
