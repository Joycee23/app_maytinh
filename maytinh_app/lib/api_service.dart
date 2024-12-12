import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  // Lưu kết quả tính tóan lên API
  Future<void> saveCalculation(String calculation, String result) async {
    final url = Uri.parse('$baseUrl/save');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'calculation': calculation, 'result': result}),
      );
      if (response.statusCode != 200) {
        throw Exception('Lưu phép tính thất bại');
      }
    } catch (e) {
      print('Lỗi khi lưu phép tính: $e');
    }
  }

  //lấy lịch ử các phép tính từ máy chủ
  Future<List<Map<String, String>>> fetchCalculationHistory() async {
    final url = Uri.parse('$baseUrl/history');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return List<Map<String, String>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Lịch sử phép tính thất bại');
      }
    } catch (e) {
      throw Exception('Lôi khi lấy lịch sử: $e');
    }
  }

  //xóa toàn bộ phesp tính trên máy chủ
  Future<void> clearCalculationHistory() async {
    final url = Uri.parse('$baseUrl/clear');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        throw Exception('Xóa lịch sử phép tính thất bại');
      }
    } catch (e) {
      throw Exception('Loi khi xóa lịch sử: $e');
    }
  }
}
