/// Payment method for an order. V1 supports cash only;
/// M-Pesa integration is planned for V2.
enum PaymentMethod { cash, mpesa }

PaymentMethod paymentMethodFromString(String? value) {
  if (value == 'mpesa') return PaymentMethod.mpesa;
  return PaymentMethod.cash;
}

String paymentMethodToString(PaymentMethod method) =>
    method == PaymentMethod.mpesa ? 'mpesa' : 'cash';
