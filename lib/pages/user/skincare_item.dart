class SkincareItem {
  final String name;
  final String type;
  final List<String> ingredients;

  SkincareItem({required this.name, required this.type, required this.ingredients});

  // Helper method to get display title based on type
  String getDisplayTitle() {
    switch (type.toLowerCase()) {
      case 'toner':
        return 'Gunakan toner pada wajah dengan kapas dan diamkan beberapa saat';
      case 'essence':
        return 'Gunakan essence pada wajah dan pijat tipis - tipis';
      case 'serum':
        return 'Gunakan serum pada wajah dan pijat tipis - tipis';
      case 'facial wash':
        return 'Mencuci wajah dengan bersih';
      case 'moisturizer':
        return 'Gunakan moisturizer pada wajah';
      case 'sunscreen':
        return 'Gunakan sunscreen pada wajah';
      case 'obat jerawat':
        return 'Gunakan obat jerawat dengan mentotol di bagian jerawat';
      default:
        return 'Gunakan skincare pada wajah';
    }
  }

  // Helper method to get image path based on type
  String getImagePath() {
    switch (type.toLowerCase()) {
      case 'toner':
        return 'assets/images/skincare/toner.jpg';
      case 'essence':
        return 'assets/images/skincare/essence.jpg';
      case 'serum':
        return 'assets/images/skincare/serum.jpg';
      case 'facial wash':
        return 'assets/images/skincare/facialwash.jpg';
      case 'moisturizer':
        return 'assets/images/skincare/moisturizer.png';
      case 'sunscreen':
        return 'assets/images/skincare/sunscreen.png';
      case 'obat jerawat':
        return 'assets/images/skincare/obatjerawat.jpg';
      default:
        return 'assets/images/skincare/default.png';
    }
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'ingredients': ingredients,
    };
  }

  // Create from map
  static SkincareItem fromMap(Map<String, dynamic> map) {
    return SkincareItem(
      name: map['name'],
      type: map['type'],
      ingredients: List<String>.from(map['ingredients']),
    );
  }
}