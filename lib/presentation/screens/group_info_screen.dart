import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../logic/group_info/group_info_controller.dart';
import '../widgets/custom_app_bar.dart';

class GroupInfoScreen extends StatelessWidget {
  const GroupInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GroupInfoController c = Get.put(GroupInfoController());
    return Scaffold(
      appBar: const CustomAppBar(title: 'Group Info'),
      body: Obx(() {
        if (c.isLoading.value && c.group.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.error.value.isNotEmpty && c.group.value == null) {
          return Center(child: Text(c.error.value));
        }
        final g = c.group.value;
        if (g == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Obx(() {
              final canEdit = c.isCurrentUserAdmin;
              return ListTile(
                title: const Text('Name'),
                subtitle: Text(g.name),
                trailing: canEdit
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          final nameCtrl = TextEditingController(text: g.name);
                          final descCtrl =
                              TextEditingController(text: g.description ?? '');
                          final avatarCtrl =
                              TextEditingController(text: g.avatar ?? '');
                          Get.dialog(
                            AlertDialog(
                              title: const Text('Edit group info'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: descCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Description',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: avatarCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Avatar URL (optional)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('Cancel')),
                                Obx(() => TextButton(
                                      onPressed: c.actionLoading.value
                                          ? null
                                          : () {
                                              c.updateGroup(
                                                name: nameCtrl.text.trim(),
                                                description:
                                                    descCtrl.text.trim(),
                                                avatar: avatarCtrl.text.trim(),
                                              );
                                              Get.back();
                                            },
                                      child: c.actionLoading.value
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Text('Save'),
                                    )),
                              ],
                            ),
                          );
                        },
                      )
                    : null,
              );
            }),
            if (g.description != null && g.description!.isNotEmpty)
              ListTile(
                title: const Text('Description'),
                subtitle: Text(g.description!),
              ),
            const Divider(),
            Obx(() {
              final canAddMembers = c.isCurrentUserAdmin;
              return ListTile(
                title: const Text('Members'),
                subtitle: Text('${g.members?.length ?? 0} members'),
                trailing: canAddMembers
                    ? IconButton(
                        icon: const Icon(Icons.person_add_alt),
                        onPressed: () {
                          final searchCtrl = TextEditingController();
                          Get.dialog(
                            Dialog(
                              child: Container(
                                width: double.maxFinite,
                                constraints:
                                    const BoxConstraints(maxHeight: 600),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Add member',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: searchCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Search users by name',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                      onChanged: (q) => c.searchUsers(q),
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: Obx(() {
                                        if (c.searching.value) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        }
                                        if (c.searchResults.isEmpty &&
                                            searchCtrl.text.trim().isEmpty) {
                                          return const Center(
                                              child: Text(
                                                  'Search for users to add'));
                                        }
                                        if (c.searchResults.isEmpty) {
                                          return const Center(
                                              child: Text('No users found'));
                                        }
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: c.searchResults.length,
                                          itemBuilder: (_, i) {
                                            final u = c.searchResults[i];
                                            return ListTile(
                                              leading: CircleAvatar(
                                                child: Text(
                                                  (u.name ?? u.email ?? u.id)
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                ),
                                              ),
                                              title: Text(
                                                  u.name ?? u.email ?? u.id),
                                              subtitle: Text(u.email ?? ''),
                                              trailing: Obx(
                                                  () => c.actionLoading.value
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2),
                                                        )
                                                      : IconButton(
                                                          icon: const Icon(
                                                              Icons.add_circle),
                                                          onPressed: () {
                                                            c.addMember(u.id);
                                                            Get.back();
                                                          },
                                                        )),
                                            );
                                          },
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            c.clearSearch();
                                            Get.back();
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              );
            }),
            ...(g.members ?? []).map(
              (m) {
                final isAdmin = m.role.toLowerCase() == 'admin';
                final isMe = m.userId == c.currentUserId;
                final subtitle = isAdmin
                    ? (isMe ? 'Admin (you)' : 'Admin')
                    : (isMe ? 'Member (you)' : 'Member');

                Widget? trailing;
                if (c.isCurrentUserAdmin) {
                  trailing = PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'make-admin') {
                        c.updateMemberRole(m.userId, 'admin');
                      } else if (value == 'make-member') {
                        c.updateMemberRole(m.userId, 'member');
                      } else if (value == 'remove') {
                        c.removeMember(m.userId);
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (!isAdmin)
                        const PopupMenuItem(
                          value: 'make-admin',
                          child: Text('Make admin'),
                        ),
                      if (isAdmin && !isMe)
                        const PopupMenuItem(
                          value: 'make-member',
                          child: Text('Make member'),
                        ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove from group'),
                      ),
                    ],
                  );
                } else if (isAdmin) {
                  trailing = const Icon(
                    Icons.verified,
                    color: Colors.amber,
                  );
                }

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (m.name ?? m.userId).substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text(m.name ?? m.userId),
                  subtitle: Text(subtitle),
                  trailing: trailing,
                );
              },
            ),
            const Divider(),
            Obx(() {
              final s = c.settings.value;
              if (s == null) {
                return ListTile(
                  title: const Text('Group settings'),
                  subtitle: const Text('Loading settings...'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: c.loadSettings,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    title: Text(
                      'Group settings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    title: const Text('Only admins can send'),
                    value: s.onlyAdminsCanSend ?? false,
                    onChanged: c.isCurrentUserAdmin
                        ? (val) => c.updateSettings(
                              {
                                // Backend expects 'all' or 'admins'
                                'whoCanSendMessages': val ? 'admins' : 'all',
                              },
                            )
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Only admins can edit info'),
                    value: s.onlyAdminsCanEditInfo ?? false,
                    onChanged: c.isCurrentUserAdmin
                        ? (val) => c.updateSettings(
                              {
                                'whoCanEditGroupInfo': val ? 'admins' : 'all',
                              },
                            )
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Approval required for new members'),
                    value: s.approvalRequired ?? false,
                    onChanged: c.isCurrentUserAdmin
                        ? (val) => c.updateSettings(
                              {
                                'approveNewMembers': val,
                              },
                            )
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Disappearing messages'),
                    value: s.disappearingMessages ?? false,
                    onChanged: c.isCurrentUserAdmin
                        ? (val) => c.updateSettings(
                              {
                                'disappearingMessages': val,
                              },
                            )
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Allow media messages'),
                    value: s.sendMediaMessages ?? true,
                    onChanged: c.isCurrentUserAdmin
                        ? (val) => c.updateSettings(
                              {
                                'sendMediaMessages': val,
                              },
                            )
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Allow links'),
                    value: s.sendLinks ?? true,
                    onChanged: c.isCurrentUserAdmin
                        ? (val) => c.updateSettings(
                              {
                                'sendLinks': val,
                              },
                            )
                        : null,
                  ),
                ],
              );
            }),
            const Divider(),
            if (c.isCurrentUserAdmin) ...[
              ListTile(
                title: const Text(
                  'Delete group',
                  style: TextStyle(color: Colors.redAccent),
                ),
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                onTap: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Delete group?'),
                      content: const Text(
                          'This will permanently delete the group and its chat for all members.'),
                      actions: [
                        TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel')),
                        Obx(() => TextButton(
                              onPressed: c.actionLoading.value
                                  ? null
                                  : () {
                                      Get.back();
                                      c.deleteGroup();
                                    },
                              child: c.actionLoading.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Delete'),
                            )),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
            ],
            ListTile(
              title: const Text('Leave group'),
              leading: const Icon(Icons.exit_to_app),
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Leave group?'),
                    actions: [
                      TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          c.leaveGroup();
                        },
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}
