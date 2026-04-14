import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyetomobile2/viewmodels/plans_viewmodel.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlansViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Planos e Assinaturas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 0,
          centerTitle: false,
          toolbarHeight: 56,
        ),
        body: Consumer<PlansViewModel>(
          builder: (context, viewModel, child) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Toggle between Monthly and Annual
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 214, 214, 216),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => viewModel.toggleBillingCycle(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: viewModel.isMonthly ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: viewModel.isMonthly
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
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
                              onTap: () => viewModel.toggleBillingCycle(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !viewModel.isMonthly ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: !viewModel.isMonthly
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: const Text(
                                  'Anual',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF9500),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Plans List
                    Expanded(
                      child: ListView(
                        children: [
                          // Essential Plan
                          _buildPlanCard(
                            context,
                            title: 'Essencial',
                            price: viewModel.getEssentialPrice(),
                            period: viewModel.getPricePeriod(),
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
                          const SizedBox(height: 20),

                          // Premium Plan
                          _buildPlanCard(
                            context,
                            title: 'Premium',
                            price: viewModel.getPremiumPrice(),
                            period: viewModel.getPricePeriod(),
                            features: [
                              'Mapas de todo o país',
                              'Priorização de pavimento',
                              'Fuga inteligente de semáforos',
                              'Sem anúncios',
                              'Filtros ilimitados',
                            ],
                            buttonText: 'Assinar',
                            isPrimary: false,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
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
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.black87 : Colors.white,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '\$',
                      style: TextStyle(
                        fontSize: 14,
                        color: isPrimary ? const Color(0xFFFF9500) : const Color(0xFFFF9500),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: price,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isPrimary ? const Color(0xFFFF9500) : const Color(0xFFFF9500),
                      ),
                    ),
                    TextSpan(
                      text: period,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPrimary ? Colors.grey[700] : Colors.grey[500],
                        fontWeight: FontWeight.w500,
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
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color: isPrimary ? const Color(0xFF1B7E3D) : const Color(0xFFFF9500),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: isPrimary ? Colors.grey[800] : Colors.grey[300],
                          fontWeight: FontWeight.w500,
                          height: 1.3,
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
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
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
                  color: isPrimary ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
