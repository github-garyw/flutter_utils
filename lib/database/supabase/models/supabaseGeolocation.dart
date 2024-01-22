
class SupabaseGeolocation {

  double longitude = 0, latitude = 0;

  SupabaseGeolocation(this.longitude, this.latitude);

  @override
  String toString() {
    return 'POINT($longitude $latitude)';
  }

}