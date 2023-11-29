import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iitb_proj/screens/pattern_lock_screen.dart';

class EnterNameScreen extends StatefulWidget {
  const EnterNameScreen({super.key});

  @override
  State<EnterNameScreen> createState() => _EnterNameScreenState();
}

class _EnterNameScreenState extends State<EnterNameScreen> {
  TextEditingController controller = TextEditingController();
  TextEditingController controller1 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter details")),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Center(
          child: Column(
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.name,
                decoration:
                    const InputDecoration(hintText: "Enter name..."),
              ),
              TextField(
                controller: controller1,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(hintText: "Enter phone number..."),
              ),
              const SizedBox(
                height: 50,
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.isEmpty || controller1.text.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Please enter all data!"),
                        icon: const Icon(Icons.warning),
                        iconColor: Colors.red,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("OK"),
                          )
                        ],
                      ),
                    );
                  } else {
                    GetStorage().write("parkinsonUserDetails", {"name" : controller.text, "number" : controller1.text});
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const PatternLockScreen(),
                    ));
                  }
                },
                child: const Text("Save and Proceed"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
