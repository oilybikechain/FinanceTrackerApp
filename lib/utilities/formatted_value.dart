String formattedValue(double valueToFormat) {
  String _temp = valueToFormat.toStringAsFixed(2);

  if (_temp.endsWith('.00')) {
    _temp = _temp.substring(0, _temp.length - 3);
  }

  return _temp;
}
