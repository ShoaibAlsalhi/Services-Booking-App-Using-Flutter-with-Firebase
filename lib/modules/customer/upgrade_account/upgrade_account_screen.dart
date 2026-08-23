import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/account_upgrade_cubit/account_upgrade_cubit.dart';
import '../../../shared/components/components.dart';

class UpgradeAccountRequestScreen extends StatefulWidget {
  final String customerId;

  const UpgradeAccountRequestScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  _UpgradeAccountRequestScreenState createState() =>
      _UpgradeAccountRequestScreenState();
}

class _UpgradeAccountRequestScreenState extends State<UpgradeAccountRequestScreen> {
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if the user has already submitted a request when the screen loads
    context.read<RequestCubit>().checkIfRequestExists(widget.customerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<RequestCubit, RequestState>(
        listener: (context, state) {
          if (state is RequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال الطلب بنجاح وفي إنتضار الوافقة من الإدارة'),
                backgroundColor: Colors.green,
              ),
            );
            // Go back after a delay
            Future.delayed(const Duration(milliseconds: 500), () {
              // Navigator.pop(context);
            });
          } else if (state is RequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is RequestUpdated) {
            // Notify the user of the request status update
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your request has been ${state.status}.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RequestLoading) {
            return buildSpinKitFadingCircle();
          } else if (state is RequestExists) {
            // Request already exists, display status
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('حالة الطلب: ${state.status}'),
                  SizedBox(height: 20),
                  if (state.status == 'New')
                    Text('لم يتم الموافقة حتى الأن')
                  else if (state.status == 'Excepted')
                    Text('تم الموافقة على طلبك!')
                  else if (state.status == 'Rejected')
                      Text('تم رفض طلب الترقية.')
                ],
              ),
            );
          } else if (state is RequestNotExist) {
            // Request doesn't exist, allow new submission
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: buildTextFormField(
                    controller: messageController,
                    maxLines: 3,
                    labelText: 'سبب ترقية الحساب ',
                    iconData: Icons.developer_board,
                    keyboardType: TextInputType.text,
                  ),
                ),
                SizedBox(height: 20),


                buildElevatedButton(
                  width: 300,
                  onPressed: () {
                    final message = messageController.text.trim();
                    if (message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('قم بتحديد سبب ترقية الحساب.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    context.read<RequestCubit>().sendUpgradeRequest(widget.customerId, message);
                  },
                  child: const Text(
                    'إرسال طلب الترقية ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Unexpected state.'));
        },
      ),
    );
  }
}
