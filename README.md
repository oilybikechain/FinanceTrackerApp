# finance_tracker

# Flutter Finance Tracker

A clean, modern, and user-friendly personal finance tracker built with Flutter. This application allows users to manage multiple accounts, track income, expenses, and transfers, and visualize their financial health through charts and statistics. The app uses an offline-first approach, storing all data locally on the device using SQLite.

## ✨ Features

- **Multi-Account Management:** Create, edit, and delete multiple financial accounts (e.g., Checking, Savings, Credit Card, Cash).
- **Transaction Logging:** Easily add income, expense, and transfer transactions with descriptions and categories.
- **Categorization:** Organize transactions with default and user-created categories, each with a custom color.
- **Recurring Transactions:** Set up recurring transactions and interest rules to automate your financial tracking. The app passively processes due items on startup.
- **Data Visualization:**
  - **Homepage:** A dashboard view with selectable accounts and time periods (Day, Week, Month, Year).
  - **Bar & Pie Charts:** Toggle between a bar chart showing income vs. expense over time and two pie charts showing the categorical breakdown of income and expenses.
  - **Data Summary:** View net change, total income, and total expense for any selected period and account(s).
- **Customizable Themes:** Switch between a sleek light mode and a comfortable dark mode. User preference is saved across sessions.
- **Offline First:** All data is stored securely and locally on your device using an **SQLite** database, ensuring privacy and offline functionality.
- **User-Friendly UI:**
  - One-tap category selection with a custom chip UI.
  - Interactive sliders for quick amount input.
  - Scrollable charts for detailed data exploration.

## 🛠️ Tech Stack & Key Packages

- **Framework:** [Flutter](https://flutter.dev/)
- **State Management:** [Provider](https://pub.dev/packages/provider) - For managing UI state and separating business logic from the UI.
- **Database:** [sqflite](https://pub.dev/packages/sqflite) - For local SQLite database storage.
- **Path Provider:** [path_provider](https://pub.dev/packages/path_provider) & [path](https://pub.dev/packages/path) - To locate and manage the database file path on the device.
- **Charts:** [fl_chart](https://pub.dev/packages/fl_chart) - A powerful and highly customizable charting library for creating bar and pie charts.
- **Date Manipulation:** [intl](https://pub.dev/packages/intl) & [jiffy](https://pub.dev/packages/jiffy) - For reliable date formatting and calculations.
- **User Preferences:** [shared_preferences](https://pub.dev/packages/shared_preferences) - For saving simple user settings like theme and chart preferences.
- **Color Picker:** [flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker) - For allowing users to select custom colors for categories.
- **Slidable Lists:** [flutter_slidable](https://pub.dev/packages/flutter_slidable) - For intuitive edit/delete actions on list items.
- **Utilities:** [collection](https://pub.dev/packages/collection) - Provides helpful extensions like `firstWhereOrNull` and `groupBy`.

