
class Pair<T, U> {

  final T firstValue;
  final U secondValue;

  Pair(this.firstValue, this.secondValue);

  @override
  String toString() {
    return 'Pair{firstValue: $firstValue, secondValue: $secondValue}';
  }

}