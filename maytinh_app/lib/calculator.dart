import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String userInput = "";
  String result = "0";
  List<String> history = [];
  bool showAdvanced = false; // Trạng thái để hiển thị nút mở rộng

  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService('https://6751e194d1983b9597b4b1c0.mockapi.io/history/calculator/:endpoint');
    loadHistoryFromLocal();
  }

  @override
  void dispose() {
    saveHistoryToLocal();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CALCULATOR"),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 3.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.centerRight,
                  child: Text(
                    userInput,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        splashColor: const Color(0xFF1d2630),
                        onTap: () => showHistory(),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1d2630),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(15),
                            child: Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        result,
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        splashColor: const Color(0xFF1d2630),
                        onTap: () => copyResult(),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1d2630),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(15),
                            child: Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showAdvanced = !showAdvanced;
                      });
                    },
                    child: Text(showAdvanced ? "Ẩn chức năng mở rộng" : "Hiện chức năng mở rộng"),
                  ),
                  Expanded(
                    child: GridView.builder(
                      itemCount: showAdvanced ? buttonListExpanded.length : buttonList.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final buttons = showAdvanced ? buttonListExpanded : buttonList;
                        return CustomButton(buttons[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget CustomButton(String text) {
    return InkWell(
      splashColor: const Color(0xFF1d2630),
      onTap: () {
        setState(() {
          handleButtons(text);
        });
      },
      child: Ink(
        decoration: BoxDecoration(
          color: getBgColor(text),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: getColor(text),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  getColor(String text) {
    if (["/", "*", "+", "-", "C", "(", ")", "log", "sin", "cos", "tan", "√", "π"].contains(text)) {
      return const Color.fromARGB(255, 252, 100, 100);
    }
    return Colors.white;
  }

  getBgColor(String text) {
    if (text == "AC") {
      return const Color.fromARGB(255, 252, 100, 100);
    }
    if (text == "=") {
      return const Color.fromARGB(255, 104, 204, 159);
    }
    return const Color(0xFF1d2630);
  }

  //xử lý thao tác tính toán
  handleButtons(String text) {
    if (text == "AC") {
      userInput = "";
      result = "0";
      return;
    }
    if (text == "C") {
      if (userInput.isNotEmpty) {
        userInput = userInput.substring(0, userInput.length - 1);
        return;
      }
    }
    if (text == "=") {
      result = calculate();
      if (result != "Error") {
        history.add("$userInput = $result");
        apiService.saveCalculation(userInput, result);
      }
      setState(() {
        userInput = result;
      });
      return;
    }
    userInput += text;
  }

  // tính toán biểu thư
  String calculate() {
    try {
      // Thay thế các ký tự đặc biệt (như π và √) bằng các giá trị tương ứng
      userInput = userInput.replaceAll("π", "3.14");
      userInput = userInput.replaceAll("√", "sqrt");
      // Phân tích biểu thức nhập vào bằng thư viện math_expressions
      var exp = Parser().parse(userInput);
      var evaluation = exp.evaluate(EvaluationType.REAL, ContextModel());

      // Trả về kết quả tính toán dưới dạng chuỗi
      return evaluation.toString();
    } catch (e) {
      // Nếu có lỗi, trả về thông báo lỗi
      return "Error";
    }
  }

  // hện lịch phesp tính
  void showHistory() async {
    try {
      // Lấy lịch sử từ API
      final fetchedHistory = await apiService.fetchCalculationHistory();
      setState(() {
        history = fetchedHistory.map((e) => "${e['calculation']} = ${e['result']}").toList();
      });
    } catch (e) {
      showErrorDialog("Lỗi khi tải lịch sử tính toán: $e");
    }

    // Hiển thị dialog với danh sách lịch sử
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Lịch sử tính toán"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(history[index]),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Đóng"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Xóa lịch sử"),
              onPressed: () {
                clearHistory();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //xóa lịch sử phép tính
  void clearHistory() async {
    try {
      // Xóa lịch sử từ API
      await apiService.clearCalculationHistory();
      setState(() {
        history = [];
      });
    } catch (e) {
      showErrorDialog("Lỗi khi xóa lịch sử tính toán: $e");
    }
  }

  // lưu lịch sử vào bộ nhớ cục bộ
  void saveHistoryToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', List<String>.from(history));
  }

  // tải toàn b lịch ử
  void loadHistoryFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final historyFromLocal = prefs.getStringList('history');
    if (historyFromLocal != null) {
      setState(() {
        history = List<String>.from(historyFromLocal);
      });
    }
  }

// Sao chép kết quả vào bộ nhớ tạm
  void copyResult() {
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kết quả đã được sao chép")),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Lỗi"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("Đóng"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

List<String> buttonList = [
  "7", "8", "9", "/", 
  "4", "5", "6", "*", 
  "1", "2", "3", "-", 
  "0", "AC", "=", "+", 
];

List<String> buttonListExpanded = [

"(", ")",".", "=",
"tan",
  "π", "sin", "cos",
  "√", "log"
];
