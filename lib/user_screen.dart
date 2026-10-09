
import 'package:flutter/material.dart';
import 'package:database_helper/database_helper.dart';
import 'package:database_helper/user.dart';

const Color bgColor = Color(0xFF0F111A);
const Color cardColor = Color(0xFF191C28);
const Color accentColor = Color(0xFFAA96FF);
const Color mutedColor = Color(0xFF9297AB);
const Color borderColor = Color(0xFF292D3D);

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final idController = TextEditingController();
  final searchController = TextEditingController();

  List<User> users = [];
  bool isLoading = true;
  int? selectedUserId;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);

    final data = await DatabaseHelper.instance.getUsers();

    if (!mounted) return;

    setState(() {
      users = data;
      isLoading = false;
    });
  }

  List<User> get filteredUsers {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return users;

    return users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.id.toString().contains(query);
    }).toList();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardColor,
      ),
    );
  }

  Future<void> addUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      showMessage('Please enter name and email.');
      return;
    }

    await DatabaseHelper.instance.insertUser(
      User(name: name, email: email),
    );

    if (!mounted) return;

    nameController.clear();
    emailController.clear();
    idController.clear();
    selectedUserId = null;

    FocusScope.of(context).unfocus();
    await loadUsers();
    showMessage('User added successfully!');
  }

  Future<void> getUserById() async {
    final id = int.tryParse(idController.text.trim());

    if (id == null) {
      showMessage('Please enter a valid user ID.');
      return;
    }

    final user = await DatabaseHelper.instance.getUserById(id);

    if (!mounted) return;

    if (user == null) {
      showMessage('User not found.');
      return;
    }

    setState(() {
      selectedUserId = user.id;
      nameController.text = user.name;
      emailController.text = user.email;
    });

    showMessage('User loaded. You can edit the details.');
  }

  Future<void> updateUser() async {
    final id = int.tryParse(idController.text.trim());
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (id == null || name.isEmpty || email.isEmpty) {
      showMessage('Enter ID, name and email.');
      return;
    }

    final rowsUpdated =
        await DatabaseHelper.instance.updateUser(id, name, email);

    if (!mounted) return;

    if (rowsUpdated == 0) {
      showMessage('User not found.');
      return;
    }

    nameController.clear();
    emailController.clear();
    idController.clear();

    setState(() => selectedUserId = null);

    FocusScope.of(context).unfocus();
    await loadUsers();
    showMessage('User updated successfully!');
  }

  Future<void> deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Delete user?'),
        content: Text('Delete ${user.name} permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DatabaseHelper.instance.deleteUser(user.id!);

    if (!mounted) return;

    if (selectedUserId == user.id) {
      nameController.clear();
      emailController.clear();
      idController.clear();
      setState(() => selectedUserId = null);
    }

    await loadUsers();
    showMessage('User deleted.');
  }

  void selectUser(User user) {
    setState(() {
      selectedUserId = user.id;
      idController.text = user.id.toString();
      nameController.text = user.name;
      emailController.text = user.email;
    });
  }

  void clearForm() {
    nameController.clear();
    emailController.clear();
    idController.clear();
    setState(() => selectedUserId = null);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    idController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers = filteredUsers;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.storage_rounded, color: accentColor, size: 27),
            SizedBox(width: 10),
            Text(
              'Userbase',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.white
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadUsers,
            icon: const Icon(Icons.refresh_rounded, color: mutedColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            const Text(
              'LOCAL DATABASE',
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                letterSpacing: 2.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your users.',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.7,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add, find, edit and remove records.',
              style: TextStyle(color: mutedColor, fontSize: 13),
            ),
            const SizedBox(height: 22),

            // Statistics card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF29233F),
                    Color(0xFF1B1D2B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: accentColor,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL USERS',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${users.length}',
                          style: const TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.dataset_linked,
                    color: accentColor,
                    size: 28,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Form heading
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage user',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (selectedUserId != null)
                  TextButton(
                    onPressed: clearForm,
                    child: const Text('Clear form'),
                    
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // User ID
            _buildInput(
              controller: idController,
              label: 'User ID',
              hint: 'Enter ID to find or update',
              icon: Icons.tag_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // Name
            _buildInput(
              controller: nameController,
              label: 'Full name',
              hint: 'e.g. Adham Saeed',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),

            // Email
            _buildInput(
              controller: emailController,
              label: 'Email address',
              hint: 'e.g. adham@example.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            // Add button
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: addUser,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: const Color(0xFF171323),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add new user',
                  style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Get and update buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: getUserById,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: const BorderSide(color: borderColor),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.search_rounded, size: 19),
                    label: const Text('Get by ID'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: updateUser,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: borderColor),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Update'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(color: borderColor),
            const SizedBox(height: 16),

            // Directory header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User directory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${visibleUsers.length} USERS',
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search
            _buildInput(
              controller: searchController,
              label: 'Search users',
              hint: 'Name, email or ID...',
              icon: Icons.search_rounded,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // User list
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(color: accentColor),
                ),
              )
            else if (visibleUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      color: mutedColor,
                      size: 42,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No users found',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Add a user or try another search.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ...visibleUsers.map((user) {
                final isSelected = selectedUserId == user.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? accentColor : borderColor,
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => selectUser(user),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: accentColor.withValues(alpha: 0.13),
                            child: Text(
                              user.name.isEmpty
                                  ? '?'
                                  : user.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: mutedColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'ID  ${user.id}',
                                  style: const TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit user',
                            onPressed: () => selectUser(user),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete user',
                            onPressed: () => deleteUser(user),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 21,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 65),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: mutedColor, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFF62677A), fontSize: 12),
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentColor, width: 1.3),
        ),
      ),
    );
  }
}
