import 'package:get/get.dart';

import '../../presentation/controllers/about_controller.dart';
import '../../presentation/controllers/change_password_controller.dart';
import '../../presentation/controllers/complaint_controller.dart';
import '../../presentation/controllers/invoice_detail_controller.dart';
import '../../presentation/controllers/material_request_controller.dart';
import '../../presentation/controllers/material_request_detail_controller.dart';
import '../../presentation/controllers/notification_controller.dart';
import '../../presentation/controllers/order_controller.dart';
import '../../presentation/controllers/stock_entry_details_controller.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../presentation/controllers/task_detail_controller.dart';

class InvoiceDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(InvoiceDetailController());
  }
}

class OrderBinding extends Bindings {
  @override
  void dependencies() {
    _ensureOrderController();
    Get.find<OrderController>().clearCart();
  }
}

class OrderHistoryBinding extends Bindings {
  @override
  void dependencies() {
    _ensureOrderController();
    Get.find<OrderController>().loadOrders();
  }
}

void _ensureOrderController() {
  if (!Get.isRegistered<OrderController>()) {
    Get.put(OrderController());
  }
}

class ComplaintBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ComplaintController());
  }
}

class StockEntryDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StockEntryDetailsController());
  }
}

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ChangePasswordController());
  }
}

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NotificationController());
  }
}

class MaterialRequestBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MaterialRequestController>()) {
      Get.lazyPut(() => MaterialRequestController());
    }
  }
}

class MaterialRequestDetailBinding extends Bindings {
  @override
  void dependencies() {
    final name = Get.arguments as String? ?? '';
    Get.put(MaterialRequestDetailController(name));
  }
}

class AboutJopticBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AboutController());
  }
}

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TaskController>()) {
      Get.lazyPut(() => TaskController());
    }
  }
}

class TaskDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TaskDetailController());
  }
}
