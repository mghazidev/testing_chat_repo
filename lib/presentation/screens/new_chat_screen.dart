import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/user_model.dart';
import '../../logic/new_chat/new_chat_controller.dart';
import '../widgets/custom_app_bar.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final NewChatController c = Get.put(NewChatController());
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'New Chat',
          bottom: TabBar(tabs: [Tab(text: 'Direct'), Tab(text: 'Group')]),
        ),
        body: TabBarView(
          children: [
            _buildDirectTab(context),
            _buildGroupTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(labelText: 'Search users', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
            onChanged: (q) => c.search(q),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (c.searching.value) return const Center(child: CircularProgressIndicator());
            if (c.error.value.isNotEmpty) return Text(c.error.value, style: const TextStyle(color: Colors.red));
            if (c.searchResults.isEmpty && c.query.isNotEmpty) return const Text('No users found');
            return Expanded(
              child: ListView.builder(
                itemCount: c.searchResults.length,
                itemBuilder: (_, i) {
                  final u = c.searchResults[i];
                  return ListTile(
                    title: Text(u.name ?? u.email ?? u.id),
                    subtitle: Text(u.email ?? ''),
                    onTap: () => c.createDirectChat(u.id),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGroupTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(labelText: 'Search users to add', border: OutlineInputBorder()),
            onChanged: (q) => c.search(q),
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (c.searchResults.isEmpty && c.query.isEmpty) {
              return const Text('Search and select members, then enter group name below.');
            }
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: c.searchResults.length,
                itemBuilder: (_, i) {
                  final u = c.searchResults[i];
                  final selected = c.isSelected(u.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(u.name ?? u.email ?? u.id),
                      selected: selected,
                      onSelected: (_) => c.toggleMember(u.id),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Group name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Obx(() => ElevatedButton(
            onPressed: c.creating.value ? null : () {
              final name = _nameController.text.trim();
              if (name.isEmpty || c.selectedMemberIds.isEmpty) {
                Get.snackbar('Error', 'Enter group name and add at least one member');
                return;
              }
              c.createGroup(
                name,
                _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                c.selectedMemberIds.toList(),
              );
            },
            child: c.creating.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Group'),
          )),
          if (c.error.value.isNotEmpty) Text(c.error.value, style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
