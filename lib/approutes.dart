
import 'package:digitalot/pages/loginpage.dart';

class AppRoutes {
  static final pages = {
    // '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginPage(),
    // '/home': (context) => HomePage(),
    // '/mainpage': (context) => const MainPage(),
    // '/profilepage': (context) => const ProfilePage(),
    // '/editprofilepage': (context) => EditProfilePage(),
    // '/signuppage': (context) => const SignUpPage(),
    // '/bioaddpage': (context) => const BioAddPage(),
    // '/searchresultscreen': (context) => const SearchResultScreen(query: ''),
    // '/notificationpage': (context) => const NotificationPage(),
    // '/connecthubpage': (context) => CallScreen(),
    // '/incomingvoicecallscreen': (context) => const IncomingVoiceCallScreen(),
    // '/outgoingcallscreen': (context) => const OutgoingCallScreen(),
    // '/forgotpasswordscreen': (context) => const ForgotPasswordScreen(),
    // // '/reset-password': (context) {
    //   // Extract the access token from arguments passed to the route
    //   final accessToken = ModalRoute.of(context)!.settings.arguments as String;
    //   return ResetPasswordScreen(accessToken: accessToken);
    // },
  };

  static const splashscreen = '/';
  static const login = '/login';
  static const home = '/home';
  static const main = '/mainpage';
  static const profile = '/profilepage';
  static const editprofile = '/editprofilepage';
  static const signup = '/signuppage';
  static const bioadd = '/bioaddpage';
  static const searchresult = '/searchresultscreen';
  static const notification = '/notificationpage';
  static const connecthubpage = '/connecthubpage';
  static const incomingvoicecallscreen = '/incomingvoicecallscreen';
  static const outgoingcallscreen = '/outgoingcallscreen';
  static const forgotpasswordscreen = '/forgotpasswordscreen';
}
