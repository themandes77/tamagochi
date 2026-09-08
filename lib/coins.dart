class CoinStore {
  CoinStore._();
  static final CoinStore instance = CoinStore._();

  static const int foodPrice = 5;
  static const int soapPrice = 3;

  int balance = 0;
  String? message;
  DateTime? messageTime;

  void add(int amount) {
    balance += amount;
  }

  bool trySpend(int amount) {
    if (balance < amount) return false;
    balance -= amount;
    return true;
  }

  void setMessage(String msg) {
    message = msg;
    messageTime = DateTime.now();
  }
}
