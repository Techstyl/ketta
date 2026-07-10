class AppStrings {
  static bool isAmharic = true;

  static String get adminPanel => isAmharic ? 'የአስተዳዳሪ ፓነል' : 'Admin Panel';
  static String get shutdownApp => isAmharic ? 'አፕሊኬሽኑን ዝጋ' : 'Shutdown App';
  static String get forceUpdate => isAmharic ? 'ማሻሻያ አስገድድ' : 'Force Update';
  static String get save => isAmharic ? 'አስቀምጥ' : 'Save';
  static String get cancel => isAmharic ? 'ሰርዝ' : 'Cancel';
  static String get confirm => isAmharic ? 'አረጋግጥ' : 'Confirm';
  static String get loading => isAmharic ? 'እየጫነ ነው...' : 'Loading...';
  static String get login => isAmharic ? 'ግባ' : 'Login';
  static String get username => isAmharic ? 'የተጠቃሚ ስም' : 'Username';
  static String get password => isAmharic ? 'የይለፍ ቃል' : 'Password';
  static String get users => isAmharic ? 'ተጠቃሚዎች' : 'Users';
}
