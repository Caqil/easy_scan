import 'package:purchases_flutter/errors.dart';
import 'package:purchases_flutter/models/purchases_error.dart';

class PurchaseUtils {
  static String? handlePurchaseError(dynamic error) {
    // Handle specific error cases
    if (error is PurchasesError) {
      switch (error.code) {
        case PurchasesErrorCode.purchaseCancelledError:
          return 'Purchase was cancelled by user';
        case PurchasesErrorCode.networkError:
          return 'Network connection failed. Please check your internet and try again';
        case PurchasesErrorCode.paymentPendingError:
          return 'Payment is processing. Please wait a moment';
        case PurchasesErrorCode.insufficientPermissionsError:
          return 'Permission denied. Please check your account settings';
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
          return 'This package is currently unavailable';
        default:
          return 'An unexpected error occurred during purchase';
      }
    }

    // Handle generic errors
    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again later';
    }

    if (error.toString().contains('authentication')) {
      return 'Authentication failed. Please sign in again';
    }

    // Default fallback
    return 'Something went wrong. Please try again or contact support';
  }
}
