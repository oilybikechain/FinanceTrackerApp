// lib/data/enums.dart

enum TransactionType { income, expense, transfer }

enum RecurringTransactionType { income, expense, transfer }

enum Frequency { daily, weekly, monthly, yearly }

enum TimePeriod { day, week, month, year }

// Helper extension for robust enum parsing from String (optional but recommended)
extension EnumParser<T extends Enum> on List<T> {
  T? fromName(String? name, {T? defaultValue}) {
    if (name == null) return defaultValue;
    for (T value in this) {
      if (value.name == name) {
        return value;
      }
    }
    return defaultValue; // Return default if name doesn't match any enum value
  }
}
