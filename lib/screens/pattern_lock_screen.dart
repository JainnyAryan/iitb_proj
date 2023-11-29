import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iitb_proj/screens/enter_name_screen.dart';

import '../utils/utils.dart';
import '../widgets/custom_pattern_lock.dart';

class PatternLockScreen extends StatefulWidget {
  const PatternLockScreen({Key? key}) : super(key: key);

  @override
  _PatternLockScreenState createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  String pattern = '';
  List points = [];

  final utils = Utils();

  TextEditingController controller =
      TextEditingController(text: "Patient is OK...");

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title:
            Text("Hello ${GetStorage().read("parkinsonUserDetails")["name"]}"),
        actions: [
          ElevatedButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white)),
            onPressed: () {
              GetStorage().remove("parkinsonUserDetails");
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const EnterNameScreen(),
              ));
            },
            child: const Text(
              "Reset Name",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Pattern: $pattern',
                style: const TextStyle(color: Colors.black),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.1,
                  horizontal: MediaQuery.of(context).size.width * 0.1,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => CustomPatternLock(
                    pointRadius: (constraints.maxHeight > constraints.maxWidth
                            ? constraints.maxWidth
                            : constraints.maxHeight) *
                        0.08,
                    circleRadiusCoefficient: 1,
                    showInput: true,
                    numberOfPoints: 9,
                    relativePadding: 0.5,
                    selectThreshold: 25,
                    fillPoints: true,
                    selectedColor: Colors.green,
                    notSelectedColor: Colors.red,
                    digitColor: Colors.white,
                    selectedDigitColor: Colors.yellowAccent,
                    onInputComplete: (userInput,
                        points,
                        times,
                        distances,
                        duration,
                        jitterInfo,
                        jitterCsvData,
                        randomPointsPositions) async {
                      final canvasSize = [
                        constraints.maxWidth,
                        constraints.maxHeight
                      ];
                      print("num of points : ${points.length}");
                      print(
                          "Total Duration: ${duration.toString()} milliseconds");
                      print("times : $times");
                      print("distances : $distances");

                      if (userInput.length == 5) {
                        print("pattern is $userInput");

                        setState(() {
                          pattern = "${userInput.join(" ")}\n$jitterInfo";
                        });

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              contentPadding: const EdgeInsets.all(15),
                              title: const Text('Clinical Assessment'),
                              content: TextField(
                                controller: controller,
                                minLines: 5,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText:
                                      "Enter your assessment of the patient...",
                                  enabledBorder: const OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        const BorderSide(color: Colors.blue),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Uploading"),
                                      ),
                                    );
                                    List jitterUserCsvData = [
                                      GetStorage()
                                          .read("parkinsonUserDetails")["name"],
                                      GetStorage().read(
                                          "parkinsonUserDetails")["number"],
                                      jitterInfo["maxJitter"],
                                      jitterInfo["avgJitter"],
                                      controller.text,
                                    ];
                                    final response =
                                        await utils.uploadPatternToAPI(
                                            offsets: points,
                                            context: context,
                                            canvasSize: canvasSize,
                                            times: times,
                                            distances: distances,
                                            duration: duration,
                                            jitterCsvData: jitterCsvData,
                                            jitterUserCsvData:
                                                jitterUserCsvData,
                                            randomPointsPositions:
                                                randomPointsPositions);

                                    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
                                      SnackBar(
                                        duration: Duration(seconds: 1),
                                        content: Text(response),
                                      ),
                                    );
                                  },
                                  child: const Text('Send'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        setState(() {
                          pattern = "Not 5 digits";
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ERR : Not five digits"),
                            ),
                          );
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
