import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class HalamanTambahSkincare extends StatefulWidget {
  @override
  _HalamanTambahSkincareState createState() => _HalamanTambahSkincareState();
}

class _HalamanTambahSkincareState extends State<HalamanTambahSkincare> {
  // Daftar ingredients berbahaya dan aturan pencampuran
  static const Map<String, List<String>> dangerousCombinations = {
    'Retinol': ['Vitamin C', 'AHA', 'BHA', 'Niacinamide'],
    'Vitamin C': ['Retinol', 'Niacinamide', 'Benzoyl Peroxide'],
    'AHA': ['Retinol', 'Benzoyl Peroxide'],
    'BHA': ['Retinol', 'Benzoyl Peroxide'],
    'Benzoyl Peroxide': ['Vitamin C', 'AHA', 'BHA', 'Retinol'],
    'Niacinamide': ['Vitamin C'],
  };

  static const List<String> harmfulIngredients = [
    'Mercury',
    'Hydroquinone',
    'Formaldehyde',
    'Parabens',
    'Phthalates'
  ];

  List<String> productTypes = [
    'Toner',
    'Essence',
    'Serum',
    'Moisturizer',
    'Obat Jerawat',
    'Sunscreen',
  ];

  List<Map<String, dynamic>> productInputs = [
    {
      'nameController': TextEditingController(),
      'type': null,
      'ingredientControllers': [TextEditingController()],
    }
  ];

  // Map untuk melacak peringatan per produk
  Map<int, List<String>> productWarnings = {};

  @override
  void initState() {
    super.initState();
    // Tampilkan info tentang ingredients berbahaya saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIngredientSafetyInfo();
    });
  }

  void _showIngredientSafetyInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Peringatan Keamanan Ingredients'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingredients Berbahaya:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...harmfulIngredients.map((ingredient) =>
                    Text('• $ingredient')).toList(),
                SizedBox(height: 16),
                Text(
                  'Kombinasi Berbahaya:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...dangerousCombinations.entries.map((entry) =>
                    Text('• ${entry.key} tidak boleh dicampur dengan: ${entry.value.join(", ")}')
                ).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Mengerti'),
            ),
          ],
        );
      },
    );
  }

  void addIngredientField(int productIndex) {
    setState(() {
      productInputs[productIndex]['ingredientControllers'].add(TextEditingController());
    });
  }

  void addProductInput() {
    setState(() {
      productInputs.add({
        'nameController': TextEditingController(),
        'type': null,
        'ingredientControllers': [TextEditingController()],
      });
    });
  }

  // Fungsi untuk memeriksa apakah sebuah kata muncul dalam teks sebagai kata utuh
  bool _containsWord(String text, String word) {
    if (text.isEmpty || word.isEmpty) return false;

    // Normalisasi teks dan kata yang dicari
    String normalizedText = text.toLowerCase().trim();
    String normalizedWord = word.toLowerCase().trim();

    // Jika teks sama persis dengan kata yang dicari
    if (normalizedText == normalizedWord) {
      return true;
    }

    // Cek apakah kata muncul di awal teks (diikuti oleh spasi)
    if (normalizedText.startsWith('$normalizedWord ')) {
      return true;
    }

    // Cek apakah kata muncul di tengah teks (diawali dan diikuti oleh spasi)
    if (normalizedText.contains(' $normalizedWord ')) {
      return true;
    }

    // Cek apakah kata muncul di akhir teks (diawali oleh spasi)
    if (normalizedText.endsWith(' $normalizedWord')) {
      return true;
    }

    return false;
  }

  // Fungsi untuk memeriksa ingredients berbahaya
  void checkIngredientSafety() {
    Map<int, List<String>> newWarnings = {};

    for (int i = 0; i < productInputs.length; i++) {
      List<String> warnings = [];
      var product = productInputs[i];

      // Ambil semua ingredients dari produk ini
      List<String> ingredients = (product['ingredientControllers'] as List<TextEditingController>)
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // Periksa ingredients berbahaya
      for (String ingredient in ingredients) {
        // Cek apakah termasuk ingredients berbahaya (menggunakan pencocokan kata utuh)
        for (String harmful in harmfulIngredients) {
          if (_containsWord(ingredient, harmful)) {
            warnings.add('$ingredient dapat berbahaya untuk kesehatan');
            break; // Cukup satu peringatan per ingredient berbahaya
          }
        }

        // Cek kombinasi berbahaya dalam produk yang sama
        for (var entry in dangerousCombinations.entries) {
          String dangerousIngredient = entry.key;
          List<String> incompatible = entry.value;

          // Cek apakah ingredient saat ini mengandung kata kunci berbahaya
          if (_containsWord(ingredient, dangerousIngredient)) {
            for (String otherIngredient in ingredients) {
              if (ingredient != otherIngredient) {
                // Cek apakah otherIngredient mengandung salah satu incompatible
                for (String inc in incompatible) {
                  if (_containsWord(otherIngredient, inc)) {
                    warnings.add('$ingredient tidak boleh dicampur dengan $otherIngredient');
                    break;
                  }
                }
              }
            }
          }
        }
      }

      // Periksa kombinasi berbahaya antar produk
      for (int j = 0; j < productInputs.length; j++) {
        if (i != j) {
          var otherProduct = productInputs[j];
          List<String> otherIngredients = (otherProduct['ingredientControllers'] as List<TextEditingController>)
              .map((c) => c.text.trim())
              .where((text) => text.isNotEmpty)
              .toList();

          for (String ingredient in ingredients) {
            for (var entry in dangerousCombinations.entries) {
              String dangerousIngredient = entry.key;
              List<String> incompatible = entry.value;

              // Cek apakah ingredient saat ini mengandung kata kunci berbahaya
              if (_containsWord(ingredient, dangerousIngredient)) {
                for (String otherIngredient in otherIngredients) {
                  // Cek apakah otherIngredient mengandung salah satu incompatible
                  for (String inc in incompatible) {
                    if (_containsWord(otherIngredient, inc)) {
                      warnings.add('$ingredient (dalam produk ${i+1}) tidak boleh digunakan bersamaan dengan $otherIngredient (dalam produk ${j+1})');
                      break;
                    }
                  }
                }
              }
            }
          }
        }
      }

      if (warnings.isNotEmpty) {
        newWarnings[i] = warnings;
      }
    }

    setState(() {
      productWarnings = newWarnings;
    });
  }

  @override
  void dispose() {
    for (var product in productInputs) {
      product['nameController'].dispose();
      for (var controller in product['ingredientControllers']) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF109E88),
                width: 1.0,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 20, right: 20),
            child: AppBar(
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF109E88),
                    width: 1.0,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Color(0xFF109E88)),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                ),
              ),
              title: const Text(
                'SKINCARE',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF109E88),
                ),
              ),
              // TAMBAHAN: Icon info di header
              actions: [
                IconButton(
                  icon: Icon(Icons.info_outline, color: Color(0xFF109E88)),
                  onPressed: _showIngredientSafetyInfo,
                  tooltip: 'Informasi Keamanan Ingredients',
                ),
              ],
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product input sections
                ...productInputs.asMap().entries.map((entry) {
                  int index = entry.key;
                  var product = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index > 0) Divider(
                        color: Color(0xFF109E88),
                        thickness: 1,
                      ),
                      SizedBox(height: index > 0 ? 20 : 0),

                      // Tampilkan peringatan jika ada
                      if (productWarnings.containsKey(index))
                        ...productWarnings[index]!.map((warning) =>
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange[800]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      warning,
                                      style: TextStyle(color: Colors.orange[800]),
                                    ),
                                  ),
                                ],
                              ),
                            )
                        ).toList(),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Nama Produk',
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontSize: 16,
                              color: Color(0xFF109E88),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: product['nameController'],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Jenis Produk',
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 16,
                          color: Color(0xFF109E88),
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: productTypes.map((type) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: type,
                                groupValue: product['type'],
                                onChanged: (value) {
                                  setState(() {
                                    product['type'] = value;
                                  });
                                },
                                activeColor: Color(0xFF109E88),
                              ),
                              Text(
                                type,
                                style: TextStyle(
                                  fontFamily: 'Afacad',
                                  color: Color(0xFF109E88),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ingredients',
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontSize: 16,
                              color: Color(0xFF109E88),
                            ),
                          ),
                          Row(
                            children: [
                              // Tombol info ingredients berbahaya
                              IconButton(
                                icon: Icon(Icons.info_outline, color: Color(0xFF109E88)),
                                onPressed: _showIngredientSafetyInfo,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(0xFF109E88),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.add, color: Colors.white),
                                  onPressed: () => addIngredientField(index),
                                  padding: EdgeInsets.all(8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Column(
                        children: List.generate(
                          product['ingredientControllers'].length,
                              (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextField(
                              controller: product['ingredientControllers'][i],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.check_circle,
                                      color: _isIngredientSafe(product['ingredientControllers'][i].text)
                                          ? Colors.green
                                          : Colors.orange),
                                  onPressed: () {},
                                ),
                              ),
                              onChanged: (value) {
                                // Periksa keamanan setiap kali ingredients diubah
                                checkIngredientSafety();
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: index < productInputs.length - 1 ? 20 : 0),
                    ],
                  );
                }).toList(),

                ElevatedButton(
                  onPressed: addProductInput,
                  child: Text('TAMBAH'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF109E88),
                    side: BorderSide(color: Color(0xFF109E88)),
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 12),

                // Tampilkan peringatan global jika ada
                if (productWarnings.isNotEmpty &&
                    productWarnings.values.any((warnings) => warnings.isNotEmpty))
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[800]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Perhatian: Terdeteksi kombinasi ingredients yang berpotensi berbahaya. Harap periksa peringatan di atas.',
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                      ],
                    ),
                  ),

                ElevatedButton(
                  onPressed: () async {
                    // Validasi akhir sebelum menyimpan
                    checkIngredientSafety();

                    if (productWarnings.isNotEmpty &&
                        productWarnings.values.any((warnings) => warnings.isNotEmpty)) {
                      // Tampilkan konfirmasi jika ada peringatan
                      bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Peringatan Keamanan'),
                            content: Text('Ada ingredients yang berpotensi berbahaya. Yakin ingin melanjutkan?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('Lanjutkan'),
                              ),
                            ],
                          );
                        },
                      );

                      if (!confirm) return;
                    }

                    try {
                      // Prepare products data
                      final products = productInputs.map((p) {
                        // Filter out empty ingredients
                        final ingredients = (p['ingredientControllers'] as List<TextEditingController>)
                            .map((c) => c.text.trim())
                            .where((text) => text.isNotEmpty)
                            .toList();

                        return {
                          'name': p['nameController'].text.trim(),
                          'type': p['type'],
                          'ingredients': ingredients,
                        };
                      }).where((p) =>
                      p['name'].isNotEmpty &&
                          p['type'] != null &&
                          p['ingredients'].isNotEmpty
                      ).toList();

                      if (products.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Harap isi setidaknya satu produk yang valid')),
                        );
                        return;
                      }

                      print('Products to save: ${jsonEncode(products)}');

                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      // Save to backend
                      final response = await ApiService.saveSkincareProducts(products);
                      print('Save response: $response');

                      // Hide loading
                      Navigator.pop(context);

                      // Show success and go back
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Skincare berhasil disimpan')),
                      );

                      Navigator.pushNamed(context, '/profile');

                    } catch (e) {
                      // Hide loading if still showing
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal menyimpan: ${e.toString()}')),
                      );
                    }
                  },
                  child: Text('SIMPAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF109E88),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function untuk memeriksa keamanan sebuah ingredient
  bool _isIngredientSafe(String ingredient) {
    if (ingredient.isEmpty) return true;

    String lowerIngredient = ingredient.toLowerCase();

    // Cek apakah termasuk ingredients berbahaya (menggunakan pencocokan kata utuh)
    for (String harmful in harmfulIngredients) {
      if (_containsWord(ingredient, harmful)) {
        return false;
      }
    }

    return true;
  }
}