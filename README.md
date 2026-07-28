# Cheers Hotel — Sales & Records App (V1)

Dual-platform POS replacing Cheers Hotel's manual receipt book. Staff record orders from the **desktop till** or **mobile phone** — both write to the same Firestore backend. The desktop prints every receipt via the Xprinter XP-Q80A (USB/LAN).

## Stack
- **Flutter** — single codebase → Windows desktop + Android/iOS mobile
- **Firebase** — Firestore (data + offline cache), Auth
- **ESC/POS** — receipt printing on Windows, LAN backup

## Features
- Menu management (add/edit/deactivate)
- Order recording from desktop or mobile, tagged by `source`
- Print queue — desktop auto-prints incoming mobile orders
- Daily/weekly/monthly reporting with sales charts
- Expense tracking with automatic profit/loss
- Offline-first via Firestore persistence
- Connectivity monitoring with offline banner

## Setup
```bash
flutter pub get
flutterfire configure --project=<your-firebase-project-id>
# Desktop: flutter run -d windows
# Mobile:  flutter run -d <device>
```

## Structure
```
lib/
  models/     — MenuItem, Order, Expense, PaymentMethod, DailySummary
  screens/    — Home, Menu, Order, PrintQueue, Reports, OrderHistory, Expenses
  services/   — Firestore access, printer (desktop-only)
  widgets/    — MenuItemCard, SalesChart
  utils/      — ReceiptFormatter, AppTheme, ConnectivityMonitor
```

## License
Private — Cheers Hotel, Vihiga, Mbale.
