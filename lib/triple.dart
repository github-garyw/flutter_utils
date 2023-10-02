
class Triple<T, U, V> {

  final T first;
  final U middle;
  final V last;

  Triple(this.first, this.middle, this.last);

  @override
  String toString() {
    return 'Triple{first: $first, middle: $middle, last: $last}';
  }

}