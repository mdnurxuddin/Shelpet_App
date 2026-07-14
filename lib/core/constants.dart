class AppConstants {
  static const Map<String, List<String>> bdDistricts = {
    'Dhaka': ['Dhaka City', 'Savar', 'Gazipur', 'Narayanganj', 'Tangail', 'Manikganj', 'Munshiganj', 'Rajbari', 'Madaripur', 'Gopalganj', 'Faridpur', 'Kishoreganj', 'Shariatpur'],
    'Chattogram': ['Chattogram City', 'Cox\'s Bazar', 'Feni', 'Brahmanbaria', 'Rangamati', 'Noakhali', 'Chandpur', 'Lakshmipur', 'Khagrachhari', 'Bandarban'],
    'Rajshahi': ['Rajshahi City', 'Bogra', 'Pabna', 'Naogaon', 'Sirajganj', 'Chapai Nawabganj', 'Natore', 'Joypurhat'],
    'Khulna': ['Khulna City', 'Jashore', 'Kushtia', 'Satkhira', 'Bagerhat', 'Chuadanga', 'Meherpur', 'Jhenaidah', 'Magura', 'Narail'],
    'Sylhet': ['Sylhet City', 'Moulvibazar', 'Habiganj', 'Sunamganj'],
    'Barishal': ['Barishal City', 'Bhola', 'Patuakhali', 'Pirojpur', 'Jhalokati', 'Barguna'],
    'Rangpur': ['Rangpur City', 'Dinajpur', 'Kurigram', 'Gaibandha', 'Nilphamari', 'Panchagarh', 'Thakurgaon', 'Lalmonirhat'],
    'Mymensingh': ['Mymensingh City', 'Jamalpur', 'Netrokona', 'Sherpur'],
  };

  static List<String> get allDistricts => bdDistricts.keys.toList()..sort();
}
