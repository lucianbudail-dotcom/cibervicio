import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav.dart';

class MenuItem {
  final String label;
  final VoidCallback onClick;
  final Color? color;
  MenuItem({required this.label, required this.onClick, this.color});
}

class MenuSection {
  final List<MenuItem> items;
  MenuSection({required this.items});
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    final List<MenuSection> menuSections = [
      MenuSection(items: [
        MenuItem(label: "Información sobre tu cuenta", onClick: () {}),
        MenuItem(label: "Notificaciones", onClick: () {}),
        MenuItem(label: "Ajustes", onClick: () {}),
      ]),
      MenuSection(items: [
        MenuItem(label: "Pagos", onClick: () {}),
        MenuItem(label: "Historial de puntos", onClick: () => context.go('/points')),
      ]),
      MenuSection(items: [
        MenuItem(label: "Ayuda", onClick: () {}),
        MenuItem(label: "Políticas de privacidad", onClick: () {}),
        MenuItem(label: "Condiciones de uso", onClick: () {}),
      ]),
      MenuSection(items: [
        MenuItem(label: "Cerrar sesión", onClick: () {
          authProvider.logout();
          context.go('/login');
        }),
        MenuItem(label: "Eliminar cuenta", onClick: () {}, color: Colors.red),
      ]),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 124),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                child: Column(
                  children: [
                    // Header Perfil
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF48464C).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6750A4).withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.name ?? "Usuario",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ID: ${user?.id.substring(0, user.id.length > 11 ? 11 : user.id.length) ?? 'XXX-XXX-XXX'}",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Puntos: ${user?.points ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6750A4).withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                "Cambiar foto",
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Secciones del menú
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: menuSections.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, sectionIndex) {
                        final section = menuSections[sectionIndex];
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF48464C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: section.items.asMap().entries.map((entry) {
                              final itemIndex = entry.key;
                              final item = entry.value;
                              final isLast = itemIndex == section.items.length - 1;

                              return Column(
                                children: [
                                  ListTile(
                                    onTap: item.onClick,
                                    title: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: item.color ?? Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white54,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      color: Colors.white.withOpacity(0.1),
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(),
          ),
        ],
      ),
    );
  }
}
