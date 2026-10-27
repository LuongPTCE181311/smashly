String? validateFullName(String? value) {
  if ((value ?? '').trim().length < 2) {
    return 'Họ tên phải có ít nhất 2 ký tự';
  }
  return null;
}

String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Email không được để trống';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Email không đúng định dạng';
  }
  return null;
}

String? validatePhone(String? value) {
  final phone = (value ?? '').trim();
  if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
    return 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
  if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password)) {
    return 'Mật khẩu phải có cả chữ và số';
  }
  return null;
}

String? validateConfirmPassword(String? password, String? confirm) {
  if ((confirm ?? '').isEmpty) return 'Vui lòng nhập lại mật khẩu';
  if (confirm != password) return 'Mật khẩu xác nhận không khớp';
  return null;
}

String? validateRequired(String? value, String message) {
  if ((value ?? '').trim().isEmpty) return message;
  return null;
}
