# Cheers Hotel — Sales & Records App (V1)

A dual-platform POS system replacing Cheers Hotel's manual receipt book. Staff record orders from the **desktop till** or a **staff phone**; both write to the same Firestore backend. The desktop is the only device wired to the receipt printer, so it prints every order regardless of where it was recorded.

## Stack
- **Flutter** — single codebase, two build targets (Windows desktop + Android)
- **Firebase** — Firestore (data + offline cache) and Auth
- **ESC/POS over USB** — receipt printing on Windows via the raw print spooler, LAN (port 9100) as backup

## Features (V1)
- Menu management (add/edit/deactivate items)
- Order recording on desktop or mobile, tagged by `source`
- Automatic receipt printing on the desktop for every order
- Daily / weekly / monthly reporting with top-sellers
- Expense tracking and automatic profit/loss

## Getting Started
1. `flutter pub get`
2. Run `flutterfire configure` and replace `lib/firebase_options.dart` with the generated file (a placeholder ships in this repo — **do not** commit real Firebase keys).
3. Desktop: `flutter run -d windows`
4. Mobile: `flutter run -d <android-device>`

## Project Structure
```
lib/
  models/     — MenuItem, Order, Expense
  services/   — Firestore access, printer service (desktop-only)
  screens/    — Home, Menu, Order, Reports, Expenses
  widgets/    — Reusable UI pieces
  utils/      — Receipt formatting helpers
```

## Printer Notes
The Xprinter XP-Q80A connects via USB to the till desktop. Printing code lives in `lib/services/printer_service.dart` and is only wired up on the Windows build — mobile never talks to the printer directly.

## Roadmap (V2, separately scoped)
AI business insights, M-Pesa reconciliation, inventory deduction, staff logins, true offline mode. See the project spec doc for full detail.
