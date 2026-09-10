import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/shared_widgets/input_form.dart';

class ChangeAdminPass extends StatefulWidget {
  static const routeName = '/change-admin-pass';

  final String email;
  const ChangeAdminPass({super.key, required this.email});

  @override
  State<ChangeAdminPass> createState() => _ChangeAdminPassState();
}

class _ChangeAdminPassState extends State<ChangeAdminPass> {
  bool isObscureCurrentPassword = true;
  bool isObscureNewPassword = true;
  bool isObscureConfirmNewPassword = true;
  bool isLoading = false;

  final _passController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void dispose() {
    _passController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _show(String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(text),
      ),
    );
  }

  Future<void> changePassword(String email) async {
    FocusScope.of(context).unfocus();

    final oldPass = _passController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (newPass.length < 6) {
      _show("Mật khẩu mới phải từ 6 ký tự trở lên!");
      return;
    }
    if (newPass != confirmPass) {
      _show("Vui lòng nhập đúng mật khẩu xác nhận!");
      return;
    }
    if (newPass == oldPass) {
      _show("Mật khẩu mới không được trùng mật khẩu cũ!");
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final credential =
          EmailAuthProvider.credential(email: email, password: oldPass);

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);

      _show("Đổi mật khẩu thành công!");

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
        }
      });
    } catch (e) {
      _show("Sai mật khẩu. Vui lòng thử lại!");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: AppbarIcon(),
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "Đổi mật khẩu",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bảo mật tài khoản của bạn",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Vui lòng nhập mật khẩu hiện tại và mật khẩu mới.",
                style: TextStyle(
                  color: AppColors.dark.withValues(alpha: 0.54),
                ),
              ),
              const SizedBox(height: 15),
              InputForm(
                controller: _passController,
                hintText: 'Mật khẩu hiện tại',
                icon: Icons.lock_outline,
                obscureText: isObscureCurrentPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscureCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isObscureCurrentPassword = !isObscureCurrentPassword;
                    });
                  },
                ),
              ),
              InputForm(
                controller: _newPassController,
                hintText: 'Mật khẩu mới',
                icon: Icons.lock_person_outlined,
                obscureText: isObscureNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isObscureNewPassword = !isObscureNewPassword;
                    });
                  },
                ),
              ),
              InputForm(
                controller: _confirmPassController,
                hintText: 'Xác nhận mật khẩu mới',
                icon: Icons.verified_user_outlined,
                obscureText: isObscureConfirmNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscureConfirmNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isObscureConfirmNewPassword =
                          !isObscureConfirmNewPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: isLoading ? null : () => changePassword(widget.email),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.textSecondary,
                        AppColors.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          )
                        : const Text(
                            "Đổi mật khẩu",
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
