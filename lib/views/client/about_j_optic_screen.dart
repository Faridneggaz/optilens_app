import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/about_controller.dart';
import '../../../application/controllers/language_controller.dart';

// --- Palette J-Optic (Couleurs neutres) ---
const _primaryBlue = Color(0xFF5C8DB8);
const _accentBlue = Color(0xFF75AADB);
const _dark = Color(0xFF1F2A37);
const _textGrey = Color(0xFF6B7280);
const _bg = Color(0xFFF7F8FA);

class AboutJethingsScreen extends StatelessWidget {
  const AboutJethingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AboutController());

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _primaryBlue, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'about_title'.tr,
            style: const TextStyle(
              color: _dark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildActionGrid(controller),
              _buildSectionHeader('features_title'.tr, null),
              _buildFeaturesList(),
              _buildSectionHeader('announcements_joptic'.tr, null),
              _buildAnnouncementsFeed(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 25, bottom: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo j-optic.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'J-Optic Software',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'tagline'.tr,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(AboutController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.4,
        children: [
          _ActionCard(
            icon: Icons.shopping_bag_outlined,
            label: 'action_order'.tr,
            subtitle: 'action_order_subtitle'.tr,
            color: _primaryBlue,
            onTap: () => _showOrderForm(controller),
          ),
          _ActionCard(
            icon: Icons.support_agent_outlined,
            label: 'action_complaint'.tr,
            subtitle: 'action_complaint_subtitle'.tr,
            color: Colors.redAccent,
            onTap: () => _showComplaintForm(controller),
          ),
          _ActionCard(
            icon: Icons.play_circle_outline,
            label: 'action_tutorials'.tr,
            subtitle: 'action_tutorials_subtitle'.tr,
            color: _accentBlue,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FeatureItem(
            icon: Icons.inventory_2_outlined,
            title: 'feature_stock'.tr,
            onTap: () => _openFeatureDetail(
              'feature_stock_title'.tr,
              'feature_stock_desc'.tr,
              'assets/images/stock.png',
            ),
          ),
          _FeatureItem(
            icon: Icons.point_of_sale_outlined,
            title: 'feature_sales'.tr,
            onTap: () => _openFeatureDetail(
              'feature_sales_title'.tr,
              'feature_sales_desc'.tr,
              'assets/images/vente.png',
            ),
          ),
          _FeatureItem(
            icon: Icons.shopping_cart_outlined,
            title: 'feature_purchases'.tr,
            onTap: () => _openFeatureDetail(
              'feature_purchases_title'.tr,
              'feature_purchases_desc'.tr,
              'assets/images/acheter.png',
            ),
          ),
          _FeatureItem(
            icon: Icons.people_alt_outlined,
            title: 'feature_hr'.tr,
            onTap: () => _openFeatureDetail(
              'feature_hr_title'.tr,
              'feature_hr_desc'.tr,
              'assets/images/RH.png',
            ),
          ),
          _FeatureItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'feature_accounting'.tr,
            onTap: () => _openFeatureDetail(
              'feature_accounting_title'.tr,
              'feature_accounting_desc'.tr,
              'assets/images/Donnees medicales optiques.png',
            ),
          ),
          _FeatureItem(
            icon: Icons.apps,
            title: 'feature_apps'.tr,
            onTap: () => _openFeatureDetail(
              'feature_apps_title'.tr,
              'feature_apps_desc'.tr,
              'assets/images/app.png',
            ),
          ),
          _FeatureItem(
            icon: Icons.psychology_outlined,
            title: 'feature_ai'.tr,
            onTap: () => _openFeatureDetail(
              'feature_ai_title'.tr,
              'feature_ai_desc'.tr,
              'assets/images/cerveau_ia.png',
            ),
          ),
        ],
      ),
    );
  }

  void _openFeatureDetail(String title, String desc, String imagePath) {
    Get.to(() => FeatureDetailPage(title: title, description: desc, imagePath: imagePath));
  }

  // --- FORMULAIRES CORRIGÉS POUR ÉVITER L'OVERFLOW ---

  void _showOrderForm(AboutController controller) {
    Get.bottomSheet(
      isScrollControlled: true, // Fix 1: Permet de monter plus haut
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom), // Fix 2: S'adapte au clavier
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView( // Fix 3: Permet de scroller si c'est trop petit
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('order_form_title'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 20),
                TextField(controller: controller.nameController, decoration: InputDecoration(hintText: 'hint_optique_name'.tr, filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 10),
                TextField(controller: controller.phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: 'hint_phone'.tr, filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: controller.isLoading.value ? null : () => controller.submitLead(),
                    child: controller.isLoading.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('btn_submit_request'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComplaintForm(AboutController controller) {
    Get.bottomSheet(
      isScrollControlled: true, // Fix 1
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom), // Fix 2
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: SingleChildScrollView( // Fix 3
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('complaint_form_title'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 15),
                TextField(controller: controller.complaintClientController, decoration: InputDecoration(hintText: 'hint_optique_name'.tr, filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 15),
                TextField(controller: controller.complaintDescController, maxLines: 4, decoration: InputDecoration(hintText: 'hint_complaint_desc'.tr, filled: true, fillColor: _bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: controller.isSubmittingComplaint.value ? null : () => controller.submitComplaint(),
                    child: controller.isSubmittingComplaint.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('btn_send'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _dark)
        ),
      ),
    );
  }

  Widget _buildAnnouncementsFeed() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 1,
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: _bg, child: const Icon(Icons.bolt, color: _primaryBlue, size: 20)),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mise à jour J-Optic v4.2', style: TextStyle(fontWeight: FontWeight.bold, color: _dark)),
                  Text('Nouveaux rapports d\'analyse...', style: TextStyle(color: _textGrey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const FeatureDetailPage({super.key, required this.title, required this.description, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Get.back()),
        title: Text(title, style: const TextStyle(color: _dark)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 30, color: _primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _dark)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: _textGrey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _FeatureItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _primaryBlue, size: 30),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _dark)),
          ],
        ),
      ),
    );
  }
}