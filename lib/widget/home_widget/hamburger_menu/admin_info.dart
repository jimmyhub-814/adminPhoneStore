import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/auth_helper.dart';
import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/admin.dart';
import 'package:admin/provider/admin.dart';
import 'package:admin/widget/home_widget/hamburger_menu/change_pass.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';

class AdminInfoScreen extends StatefulWidget {
  static const routeName = '/admin-info';
  const AdminInfoScreen({super.key});

  @override
  State<AdminInfoScreen> createState() => _AdminInfoPageState();
}

class _AdminInfoPageState extends State<AdminInfoScreen> {
  final ValueNotifier<bool> isEditMode = ValueNotifier<bool>(false);
  final _fullNameController = TextEditingController();
  late Future<Admin?> adminFuture;
  Admin? _admin;

  @override
  void initState() {
    super.initState();
    adminFuture = context.read<AdminProvider>().getAdminInfo();
    adminFuture.then((value) {
      if (!mounted || value == null) return;
      setState(() {
        _admin = value;
        _fillControllers(value);
      });
    });
  }

  void _fillControllers(Admin admin) {
    _fullNameController.text = admin.name;
  }

  Future<void> updateInfo(Admin oldInfo) async {
    final updated = Admin(
      id: AuthHelper.adminId,
      name: _fullNameController.text.isEmpty
          ? oldInfo.name
          : _fullNameController.text,
      email: oldInfo.email,
      adminDeviceTokens: oldInfo.adminDeviceTokens,
    );

    await Collections.admin
        .doc(AuthHelper.adminId)
        .set(updated.toMap(), SetOptions(merge: true));

    if (mounted) {
      setState(() => _admin = updated);
    }
  }

  void _editName(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cập nhật tên"),
        content: TextField(
          controller: _fullNameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Nhập tên mới...",
            filled: true,
            fillColor: AppColors.scaffoldBg.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              setState(() {});
              Navigator.pop(dialogContext);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSave(BuildContext context) async {
    if (_admin == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text('Lưu thay đổi thông tin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(dialogContext);
              isEditMode.value = false;

              try {
                await updateInfo(_admin!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lưu thông tin thành công!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Lưu thông tin thất bại. Vui lòng thử lại sau!'),
                    ),
                  );
                }
              }
            },
            child:
                const Text('Lưu', style: TextStyle(color: AppColors.surface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        leading: AppbarIcon(
          color: AppColors.surface,
        ),
        centerTitle: true,
        title: const Text(
          'Thông tin quản trị viên',
          style: TextStyle(
            color: AppColors.surface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isEditMode,
            builder: (context, edit, _) {
              return IconButton(
                icon: Icon(
                  edit ? Icons.done_rounded : Icons.edit_outlined,
                  color: AppColors.surface,
                ),
                onPressed: () {
                  final changed =
                      _fullNameController.text.trim() != (_admin?.name ?? '');

                  if (edit && changed) {
                    _confirmSave(context);
                  } else {
                    isEditMode.value = !edit;
                  }
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<Admin?>(
        future: adminFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            );
          }

          final admin = _admin ?? snapshot.data;
          if (admin == null) {
            return const Center(
              child: Text('Không có dữ liệu người dùng'),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(top: 24, bottom: 30),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    admin.name.isNotEmpty ? admin.name[0].toUpperCase() : "A",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoTile(
                'Họ và tên',
                _fullNameController.text.isEmpty
                    ? admin.name
                    : _fullNameController.text,
                Icons.person_outline,
                onTap: () => _editName(context),
              ),
              _buildInfoTile(
                'Mật khẩu',
                '********',
                Icons.lock_outline,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    ChangeAdminPass.routeName,
                    arguments: ChangeAdminPass(email: admin.email),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon,
      {VoidCallback? onTap}) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEditMode,
      builder: (context, edit, _) {
        return GestureDetector(
          onTap: edit ? onTap : null,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: edit
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.25))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.iconDisabled,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (edit)
                  const Icon(Icons.chevron_right,
                      color: AppColors.iconDisabled),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    isEditMode.dispose();
    super.dispose();
  }
}
