// lib/data/enums.dart

enum TransactionType {
  income,
  expense,
  transfer,
  interest, // Added for automatically generated interest transactions
}

enum RecurringTransactionType {
  income,
  expense,
  transfer,
  // Note: 'interest' is usually handled by separate logic based on account settings,
  // not typically as a user-defined recurring transaction template.
}

enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}

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