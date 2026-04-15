import 'package:flutter/material.dart';
import '../../widgets/header.dart';
import '../../../domain/response/Customer.dart';
import 'complaint_form_view.dart';
import '../../views/client/order_history_page.dart'; 

class ProfilePage extends StatelessWidget {
  final Customer customer;
  final String customerCode;

  const ProfilePage({
    super.key,
    required this.customer,
    required this.customerCode,
  });

  Widget sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, top: 25, bottom: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget settingItem(String title, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 26),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 253),
      body: Column(
        children: [
          AppHeader(
            title: "",
            customer: customer,
            customerCode: customerCode,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  sectionTitle("Profile Information"),
                  Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                            'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png',
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                customer.email ?? 'No email available',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                
                  sectionTitle("Activités"),
                  settingItem(
                    "Mes Commandes", 
                    Icons.shopping_bag_outlined, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderHistoryPage(),
                        ),
                      );
                    },
                  ),

                  sectionTitle("Security Settings"),
                  settingItem("Change Password", Icons.lock, onTap: () {}),
                  
                  sectionTitle("Notification Preferences"),
                  settingItem(
                    "Manage Notifications",
                    Icons.notifications,
                    onTap: () {},
                  ),

                  sectionTitle("Support"),
                  settingItem(
                    "Déposer une réclamation", 
                    Icons.assignment_late_outlined, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintFormPage(customer: customer),
                        ),
                      );
                    },
                  ),
                  
                  settingItem("About Us", Icons.info_outline, onTap: () {}),
                  settingItem(
                    "Help & Support",
                    Icons.help_outline,
                    onTap: () {},
                  ),
                
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}