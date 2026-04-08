import 'package:flutter/material.dart';
import 'package:apskina/services/api_service.dart';

class HalamanRegister extends StatefulWidget {
  const HalamanRegister({Key? key}) : super(key: key);

  @override
  _HalamanRegisterState createState() => _HalamanRegisterState();
}

class _HalamanRegisterState extends State<HalamanRegister> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _noHandphoneController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tanggalLahirController.text =
        "${picked.day.toString().padLeft(2,'0')}/${picked.month.toString().padLeft(2,'0')}/${picked.year}";
      });
    }
  }

  Future<void> _register() async {
    print('Memulai proses register...');
    print('Data yang akan dikirim:');
    print('Nama: ${_namaController.text}');
    print('Email: ${_emailController.text}');
    print('Tanggal Lahir: ${_tanggalLahirController.text}');
    print('No HP: ${_noHandphoneController.text}');
    print('Alamat: ${_alamatController.text}');

    if (_namaController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _tanggalLahirController.text.isEmpty ||
        _noHandphoneController.text.isEmpty ||
        _alamatController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Semua field harus diisi'))
      );
      return;
    }

    // Validate email format
    if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Format email tidak valid'))
      );
      return;
    }

    if (!_noHandphoneController.text.startsWith('8') ||
        _noHandphoneController.text.length < 10 ||
        _noHandphoneController.text.length > 13) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nomor handphone harus dimulai dengan 8 dan 10-13 digit'))
      );
      return;
    }

    if(_passwordController.text != _konfirmasiPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password tidak sama'))
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password minimal 8 karakter'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try{
      final phoneNumber = '+62${_noHandphoneController.text.trim()}';
      print('Mengirim request ke backend...');

      final response = await ApiService.register(
        _namaController.text.trim(),
        _emailController.text.trim(),
        _tanggalLahirController.text.trim(),
        phoneNumber,
        _alamatController.text.trim(),
        _passwordController.text.trim(),
        _konfirmasiPasswordController.text.trim()
      );

      print('Response dari backend: $response');

      //otw ke login
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register berhasil! Silahkan login'))
      );
      Navigator.pushReplacementNamed(context, '/login', arguments: {'isMandatory': true});
    } catch (e) {
      print('Error selama registrasi: $e');

      String errorMessage = 'Register gagal!';
      if (e.toString().contains('email')) {
        errorMessage = 'Email sudah terdaftar atau format salah';
      } else if (e.toString().contains('password')) {
        errorMessage = 'Password minimal 8 karakter';
      } else if (e.toString().contains('handphone')) {
        errorMessage = 'Format nomor handphone salah';
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage))
      );
    }finally{
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset('assets/images/logo.png', width: 200),
              const SizedBox(height: 30),
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF109E88),
                  fontFamily: 'HindSiliguri',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF109E88),
                  fontFamily: 'Afacad',
                ),
              ),
              const SizedBox(height: 40),

              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // Lebar 80% dari layar
                  child: Column(
                    children: [
                      // Row Nama dan Email
                      Row(
                        children: [
                          Expanded(
                            child: _buildConnectedInputField(Icons.person, 'Name', controller: _namaController),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildConnectedInputField(Icons.calendar_today, 'Tanggal Lahir', controller: _tanggalLahirController, readOnly: true, onTap: () => _selectDate(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Date of Birth Field
                      _buildConnectedInputField(Icons.email, 'Email', controller: _emailController),
                      const SizedBox(height: 20),

                      // Phone Number Field (special case without icon circle)
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Text(
                              '+62',
                              style: TextStyle(
                                color: Color(0xFF109E88),
                                fontFamily: 'Afacad',
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildPhoneInputField(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Address Field
                      _buildConnectedInputField(Icons.location_on, 'Alamat', controller: _alamatController),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildConnectedInputField(Icons.lock, 'Password', isPassword: true, controller: _passwordController),
                      const SizedBox(height: 20),

                      // Confirm Password Field
                      _buildConnectedInputField(Icons.lock_outline, 'Confirm Password', isPassword: true, controller: _konfirmasiPasswordController),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),

              // Register Button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text(
                    'DAFTAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF109E88),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Login Text
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
                child:Text(
                  'Login disini',
                  style: TextStyle(
                    color: const Color(0xFF109E88),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF109E88),
                    decorationThickness: 1.0,
                    height: 6
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedInputField(IconData icon, String hintText, {bool isPassword = false, TextEditingController? controller, bool readOnly = false, VoidCallback? onTap}) {
    return Container(
      height: 50, // Increased height for better proportions
      child: Stack(
        children: [
          // Text Field Background (right side only)
          Positioned(
            left: 25, // Half of the circle width
            right: 0,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                border: Border.all(
                  color: Color(0xFFD9D9D9),
                  width: 1,
                ),
              ),
            ),
          ),

          // Icon and Text Field Row
          Row(
            children: [
              // Circular Icon Container
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFD9D9D9),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Color(0xFF109E88),
                    size: 20, // Slightly larger icon
                  ),
                ),
              ),

              // Text Field
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: 15), // Adjusted padding
                    child: TextField(
                      controller: controller,
                      obscureText: isPassword,
                      readOnly: readOnly,
                      onTap: onTap,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: Color(0xFF109E88),
                          fontFamily: 'Afacad',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      style: TextStyle(
                        color: Color(0xFF109E88),
                        fontFamily: 'Afacad',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: Color(0xFFD9D9D9),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _noHandphoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'No. Handphone',
            hintStyle: TextStyle(
              color: Color(0xFF109E88),
              fontFamily: 'Afacad',
            ),
            border: InputBorder.none,
          ),
          style: TextStyle(
            color: Color(0xFF109E88),
            fontFamily: 'Afacad',
          ),
        ),
      ),
    );
  }
}