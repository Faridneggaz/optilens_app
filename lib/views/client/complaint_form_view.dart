import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/complaint_controller.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/language_controller.dart';
import '../../../application/controllers/session_controller.dart';

class ComplaintFormPage extends StatelessWidget {
  const ComplaintFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c        = Get.put(ComplaintController());
    final customer = Get.find<SessionController>().customer.value!;
    final formKey  = GlobalKey<FormState>();
    final descCtrl = TextEditingController();

    const Color themeColor = Color.fromARGB(255, 0, 169, 157);

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromARGB(255, 247, 255, 253),
        body: Column(
          children: [
            AppHeader(
                title: '',
                customer: customer,
                customerCode: customer.code),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _sectionTitle('complaint_details_title'.tr,
                          Icons.description_outlined, themeColor),
                      const SizedBox(height: 15),

                      Container(
                        decoration: _cardDecoration(),
                        child: TextFormField(
                          controller: descCtrl,
                          maxLines: 8,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'complaint_hint'.tr,
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(20),
                          ),
                          validator: (v) =>
                              v!.isEmpty
                                  ? 'complaint_validation_error'.tr
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 30),

                      _sectionTitle('complaint_date_title'.tr,
                          Icons.calendar_today_outlined, themeColor),
                      const SizedBox(height: 15),
                      _datePill(),

                      const SizedBox(height: 50),

                      Obx(() => SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: c.isLoading.value
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      final ok = await c.submitComplaint(
                                        client:      customer.name,
                                        description: descCtrl.text,
                                      );
                                      if (ok) {
                                        descCtrl.clear();
                                        formKey.currentState!.reset();
                                        Get.snackbar(
                                            'success'.tr,
                                            'complaint_success_msg'.tr,
                                            backgroundColor: Colors.green,
                                            colorText: Colors.white);
                                        Get.back();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F2837),
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(15)),
                              ),
                              child: c.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text('btn_submit'.tr,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2837))),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    );
  }

  Widget _datePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12)),
      child: Text('${DateTime.now()}'.split(' ')[0],
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}