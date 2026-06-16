import 'package:flutter/foundation.dart';

class TransactionNotifier {
  // Global notifier to trigger UI updates across screens when a transaction is added
  static final ValueNotifier<int> notifier = ValueNotifier(0);
  
  static void notifyChanged() {
    notifier.value++;
  }
}
