import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:service_booking_app/layout/customer_layout.dart';
import 'package:service_booking_app/modules/login/login_screen.dart';

import '../../cubits/sign_up_cubit/sign-up_states.dart';
import '../../cubits/sign_up_cubit/sign_up_cubit.dart';
import '../../shared/components/components.dart';
import '../../shared/styles/colors.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFFDF5FC),
        // appBar: AppBar(
        //   title: const Text('Sign Up'),
        // ),
        body: SingleChildScrollView(
          child: BlocProvider(
            create: (_) => SignUpCubit(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocBuilder<SignUpCubit, SignUpState>(
                builder: (context, state) {
                  final cubit = context.read<SignUpCubit>();

                  // Handle successful sign-up and navigate to CustomerLayout
                  if (state is SignUpSuccess) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CustomerLayout()),
                      );
                    });
                  }

                  String? nameError;
                  String? emailError;
                  String? passwordError;
                  String? phoneError;

                  if (state is SignUpValidationError) {
                    nameError = state.nameError;
                    emailError = state.emailError;
                    passwordError = state.passwordError;
                    phoneError = state.phoneError;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      Lottie.asset(
                        'assets/animation/sign-up.json',
                        repeat: true,
                        reverse: true,
                        width: 300,
                        height: 300,
                      ),
                      const Text(
                        'إنشاء حساب',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      buildTextFormField(
                        controller: nameController,
                        labelText: 'الاسم',
                        iconData: Icons.person,
                        keyboardType: TextInputType.name,
                        errorText: nameError,
                        onChanged: (_) {
                          cubit.clearNameError();
                        },
                      ),
                      const SizedBox(height: 7),
                      buildTextFormField(
                        controller: emailController,
                        labelText: 'البريد الالكتروني',
                        iconData: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        errorText: emailError,
                        onChanged: (_) {
                          cubit.clearEmailError();
                        },
                      ),
                      const SizedBox(height: 7),
                      buildTextFormField(
                        controller: passwordController,
                        labelText: 'كلمة السر',
                        iconData: Icons.password,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: cubit.isPasswordVisible,
                        suffixIcon: IconButton(
                          onPressed: () {
                            cubit.changePasswordVisibility();
                          },
                          icon: Icon(cubit.suffix),
                        ),
                        errorText: passwordError,
                        onChanged: (_) {
                          cubit.clearPasswordError();
                        },
                      ),
                      const SizedBox(height: 7),
                      buildTextFormField(
                        controller: phoneController,
                        labelText: 'رقم الهاتف',
                        iconData: Icons.phone,
                        keyboardType: TextInputType.phone,
                        errorText: phoneError,
                        onChanged: (_) {
                          cubit.clearPhoneError();
                        },
                      ),
                      const SizedBox(height: 20),
                      if (state is SignUpLoading)
                         buildSpinKitFadingCircle()
                      else
                        SizedBox(
                          width: double.infinity,
                          child: buildElevatedButton(
                            onPressed: () {
                              final name = nameController.text;
                              final email = emailController.text;
                              final password = passwordController.text;
                              final phone = phoneController.text;

                              cubit.signUp(name, email, password, phone);
                            },
                            child: const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        child: Text(
                          'يوجد لديا حساب بالفعل',
                          style: TextStyle(color: textColor),
                          semanticsLabel: 'go to Sign up Login Screen',
                        ),
                      ),
                    ],
                  );
                },
              )

            ),
          ),
        ),
      ),
    );
  }
}
