import 'package:flutter/material.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  bool isMonthly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos e Assinaturas'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Toggle between Monthly and Annual
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 209, 209, 209),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isMonthly = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isMonthly ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Mensal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B7E3D),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isMonthly = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isMonthly ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Anual',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFA500),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Essential Plan
              _buildPlanCard(
                title: 'Essencial',
                price: isMonthly ? '\$0' : '\$0',
                period: isMonthly ? '/mês' : '/ano',
                features: [
                  'Rota mais curta',
                  'Acesso sem Internet',
                  'Alertas de navegação',
                  'Cidade base gratuita',
                  'Filtros limitados',
                ],
                buttonText: 'Já possuo',
                isPrimary: true,
              ),
              const SizedBox(height: 16),

              // Premium Plan
              _buildPlanCard(
                title: 'Premium',
                price: isMonthly ? '\$5' : '\$50',
                period: isMonthly ? '/mês' : '/ano',
                features: [
                  'Mapas de todo o país',
                  'Priorização de pavimento',
                  'Fuga inteligente de semáforos',
                  'Sem anúncios',
                  'Filtros limitados',
                ],
                buttonText: 'Assinar',
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required String buttonText,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : Colors.grey[900],
        border: Border.all(
          color: isPrimary ? Colors.grey[300]! : Colors.grey[700]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.black : Colors.white,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: price,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? const Color(0xFF1B7E3D) : const Color(0xFF1B7E3D),
                      ),
                    ),
                    TextSpan(
                      text: period,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPrimary ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Features List
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check,
                      size: 18,
                      color: isPrimary ? const Color(0xFF1B7E3D) : const Color(0xFFFFA500),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: isPrimary ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Botón de acción: Asegurar plan o información
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(buttonText),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? const Color(0xFF1B7E3D) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
