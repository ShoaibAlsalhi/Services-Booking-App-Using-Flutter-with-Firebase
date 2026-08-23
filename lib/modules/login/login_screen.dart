import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:service_booking_app/shared/styles/colors.dart';
import '../../cubits/login_cubit/login_cubit.dart';
import '../../cubits/login_cubit/login_states.dart';
import '../../shared/components/components.dart';
import '../sign_up/sign_up_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFFDF5FC),
        // appBar: AppBar(
        //   title: const Text('Login'),
        // ),
        body: SingleChildScrollView(
          child: BlocProvider(
            create: (_) => LoginCubit(),
            child: Column(
              children: [
                SizedBox(height: 40,),
                Lottie.asset(
                  'assets/animation/login.json',
                  repeat: true,
                  reverse: true,
                  width: 280,
                  height: 250,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BlocConsumer<LoginCubit, LoginState>(
                    listener: (context, state) {
                      // if (state is LoginError) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     SnackBar(
                      //       content: Text(state.errorMessage),
                      //       backgroundColor: Colors.red,
                      //     ),
                      //   );
                      // }
                    },
                    builder: (context, state) {
                      final cubit = context.read<LoginCubit>();

                      String? emailError;
                      String? passwordError;

                      if (state is LoginValidationError) {
                        emailError = state.emailError;
                        passwordError = state.passwordError;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تسجيل الدخول',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          buildTextFormField(
                            controller: emailController,
                            labelText: 'البريد الالكتروني',
                            iconData: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            errorText: emailError,
                          ),
                          const SizedBox(height: 20),
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
                          ),
                          const SizedBox(height: 20),
                          if (state is LoginLoading)
                            buildSpinKitFadingCircle()
                          else
                            SizedBox(
                              width: double.infinity,
                              child: buildElevatedButton(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  final email = emailController.text;
                                  final password = passwordController.text;
                                  cubit.login(email, password, context);
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
                          SizedBox(height: 10,),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SignUpScreen()),
                              );
                            },
                            child: Text(
                              'ليس لديك حساب ؟ قم بإنشاء حساب ',
                              style: TextStyle(color: textColor,fontSize: 16),
                              semanticsLabel: 'go to Sign up screen to create a new account',
                            ),
                          ),

                          // SizedBox(height: 10),
                          if (state is LoginLoading)
                            CircularProgressIndicator()
                          else
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                ' نسيت كلمة المرور ؟!!',
                                style: TextStyle(color: Colors.blue, fontSize: 16),
                              ),
                            ),


                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



}



////////////////


class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('إعادة تعيين كلمة المرور')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              buildTextFormField(
                controller: emailController,
                labelText: 'البريد الإلكتروني',
                iconData: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              BlocConsumer<LoginCubit, LoginState>(
                listener: (context, state) {
                  if (state is ResetPasswordSuccess) {
                    _showSuccessDialog(
                        context: context,
                        message: 'تم ارسال رسالة عبر البريد الالكتروني بإعادة تعين كلمة المرور يرجاء الاطلاع عليها لمتابعة تعين كلمة السر');
                  } else if (state is ResetPasswordError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.resetPasswordError),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return state is LoginLoading
                      ? buildSpinKitFadingCircle()
                      : SizedBox(
                    width: double.infinity,
                    child: buildElevatedButton(
                      onPressed: () {
                        final email = emailController.text.trim();
                        context.read<LoginCubit>().resetPassword(email,context);
                      },
                      child: Text('إرسال'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

    );

  }


  void _showSuccessDialog({required String message, required BuildContext context}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Lottie.asset(
            'assets/animation/reset_password.json',
            repeat: true,
            reverse: true,
            width: 100,
          ),
          content: Text(message),
          actions: [
            Center(
              child: Container(
                width: 200,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF3F8594)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  child: Text('موافق', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


}
