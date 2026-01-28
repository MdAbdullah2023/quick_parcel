import 'package:flutter/material.dart';
import 'package:quick_parcel/coustomer/login.dart';
import 'package:quick_parcel/services/widget_support.dart';

class SendPackage extends StatefulWidget {
  const SendPackage({super.key});

  @override
  State<SendPackage> createState() => _SendPackageState();
}

class _SendPackageState extends State<SendPackage> {
  final TextEditingController pickupAddressController = TextEditingController();
  final TextEditingController pickupNameController = TextEditingController();
  final TextEditingController pickupPhoneController = TextEditingController();

  final TextEditingController dropoffAddressController =
      TextEditingController();
  final TextEditingController dropoffNameController = TextEditingController();
  final TextEditingController dropoffPhoneController = TextEditingController();

  @override
  void dispose() {
    pickupAddressController.dispose();
    pickupNameController.dispose();
    pickupPhoneController.dispose();
    dropoffAddressController.dispose();
    dropoffNameController.dispose();
    dropoffPhoneController.dispose();
    super.dispose();
  }

  void _placeOrder() {
    // validate inputs
    if (pickupAddressController.text.isEmpty ||
        pickupNameController.text.isEmpty ||
        pickupPhoneController.text.isEmpty ||
        dropoffAddressController.text.isEmpty ||
        dropoffNameController.text.isEmpty ||
        dropoffPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return; // stop kono fiel empty hole
    }

    //  success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please Login First!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // order ses e fied clear
    pickupAddressController.clear();
    pickupNameController.clear();
    pickupPhoneController.clear();
    dropoffAddressController.clear();
    dropoffNameController.clear();
    dropoffPhoneController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D7D8F),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D7D8F),
                    Color(0xFF0A5F6D),
                    Color(0xFF084A56),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // title
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 8),
                          Text(
                            "Send Package",
                            style: AppWidget.WhiteHeadlineTextStyle(30),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // pick-up details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0D7D8F).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pick-up details",
                            style: AppWidget.BoldGreenTextfeildStyle(22),
                          ),
                          const SizedBox(height: 20),
                          AppWidget.SendPackageTextfield(
                            controller: pickupAddressController,
                            icon: Icons.location_on,
                            hint: "Enter pick-up address",
                          ),
                          const SizedBox(height: 15),
                          AppWidget.SendPackageTextfield(
                            controller: pickupNameController,
                            icon: Icons.person,
                            hint: "Enter user name",
                          ),
                          const SizedBox(height: 15),
                          AppWidget.SendPackageTextfield(
                            controller: pickupPhoneController,
                            icon: Icons.phone,
                            hint: "Enter phone number",
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // drop-off
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0D7D8F).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Drop-off details",
                            style: AppWidget.BoldGreenTextfeildStyle(22),
                          ),
                          const SizedBox(height: 20),
                          AppWidget.SendPackageTextfield(
                            controller: dropoffAddressController,
                            icon: Icons.location_on,
                            hint: "Enter drop-off address",
                          ),
                          const SizedBox(height: 15),
                          AppWidget.SendPackageTextfield(
                            controller: dropoffNameController,
                            icon: Icons.person,
                            hint: "Enter user name",
                          ),
                          const SizedBox(height: 15),
                          AppWidget.SendPackageTextfield(
                            controller: dropoffPhoneController,
                            icon: Icons.phone,
                            hint: "Enter phone number",
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    //  order button
                    GestureDetector(
                      onTap: _placeOrder,

                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2.6,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFF0D7D8F),

                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D7D8F).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "Place Order",
                              style: AppWidget.WhiteHeadlineTextStyle(19),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
