import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/doctor/doctor_dashboard.dart';
import 'screens/nurse/nurse_dashboard.dart';
import 'screens/medical_store/medical_store_dashboard.dart';
import 'screens/lab_store/lab_store_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/profile_completion/patient_profile_completion.dart';
import 'screens/profile_completion/doctor_profile_completion.dart';
import 'screens/profile_completion/nurse_profile_completion.dart';
import 'screens/profile_completion/medical_store_profile_completion.dart';
import 'screens/profile_completion/lab_store_profile_completion.dart';

void main() {
  runApp(const MedicalApp());
}

class MedicalApp extends StatelessWidget {
  const MedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seevak Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/patient-dashboard': (context) => const PatientDashboard(),
        '/doctor-dashboard': (context) => const DoctorDashboard(),
        '/nurse-dashboard': (context) => const NurseDashboard(),
        '/medical-store-dashboard': (context) => const MedicalStoreDashboard(),
        '/lab-store-dashboard': (context) => const LabStoreDashboard(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/patient-profile-completion': (context) => const PatientProfileCompletion(),
        '/doctor-profile-completion': (context) => const DoctorProfileCompletion(),
        '/nurse-profile-completion': (context) => const NurseProfileCompletion(),
        '/medical-store-profile-completion': (context) => const MedicalStoreProfileCompletion(),
        '/lab-store-profile-completion': (context) => const LabStoreProfileCompletion(),
      },
    );
  }
}
