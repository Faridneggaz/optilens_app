import 'package:flutter/material.dart';
import '../../application/controllers/complaint_controller.dart';
import '../../widgets/header.dart';
import '../../../domain/response/Customer.dart';

class ComplaintFormPage extends StatefulWidget {
  final Customer customer;
  const ComplaintFormPage({super.key, required this.customer});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = ComplaintController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  void _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await _controller.submitComplaint(
      client: widget.customer.name,
      description: _descController.text,
    );
    setState(() => _isLoading = false);

    if (success) {
      _descController.clear();
      _formKey.currentState!.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Réclamation envoyée !"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thème Teal Optilens
    const Color themeColor = Color.fromARGB(255, 0, 169, 157);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 253),
      body: Column(
        children: [
          AppHeader(title: "Réclamation", customer: widget.customer, customerCode: widget.customer.code),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Titre "Pro"
                    _buildSectionTitle("Détails du problème", Icons.description_outlined, themeColor),
                    const SizedBox(height: 15),

                    // Champ de description stylisé
                    Container(
                      decoration: _cardDecoration(),
                      child: TextFormField(
                        controller: _descController,
                        maxLines: 8,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Décrivez votre réclamation ici...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        validator: (v) => v!.isEmpty ? "La description est requise pour nous aider" : null,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Section Date Automatique
                    _buildSectionTitle("Date de la réclamation", Icons.calendar_today_outlined, themeColor),
                    const SizedBox(height: 15),
                    _buildDisabledDateField(themeColor),

                    const SizedBox(height: 50),

                    // Bouton "Sauvegarder" de ton image web
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F2837), 
                          elevation: 10,
                          shadowColor: const Color(0xFF1F2837).withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SOUMETTRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers pour la construction du design

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2837))),
      ],
    );
  }

  // Même décoration que l'AnnouncementCard
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Champ de date non modifiable
  Widget _buildDisabledDateField(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${DateTime.now()}".split(' ')[0], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          
        ],
      ),
    );
  }
}