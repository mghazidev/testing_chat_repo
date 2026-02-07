import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../logic/auth/auth_controller.dart';
import '../../logic/profile/profile_controller.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProfileController c = Get.put(ProfileController());
    final AuthController auth = Get.find<AuthController>();
    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile', elevation: 1),
      body: Obx(() {
        if (c.isLoading.value && c.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final u = c.user.value;
        if (u == null) return const Center(child: Text('No profile'));

        final nameController = TextEditingController(text: u.name ?? '');
        final emailController = TextEditingController(text: u.email ?? '');
        final phoneController = TextEditingController(text: u.phone ?? '');
        final bioController = TextEditingController(text: u.bio ?? '');

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: Text(
                            (u.name ?? '').isNotEmpty
                                ? (u.name![0].toUpperCase())
                                : '?',
                            style: TextStyle(
                                fontSize: 28,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          u.name ?? '',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          u.email ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          enabled: false,
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          enabled: false,
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: bioController,
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            prefixIcon: const Icon(Icons.info_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Obx(() => SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: c.saving.value
                                    ? null
                                    : () {
                                        c.updateProfile(
                                          name: nameController.text.trim(),
                                          phone: phoneController.text.trim(),
                                          bio: bioController.text.trim(),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: c.saving.value
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save',
                                        style: TextStyle(fontSize: 16)),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () => auth.logout(),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
