import 'package:get/get.dart';

import '../../Presentation/modules/chat/bindings/chat_binding.dart';
import '../../Presentation/modules/chat/views/chat_view.dart';
import '../../Presentation/modules/friends/bindings/friends_binding.dart';
import '../../Presentation/modules/friends/views/friends_view.dart';
import '../../Presentation/modules/homepages/bindings/homepages_binding.dart';
import '../../Presentation/modules/homepages/views/homepages_view.dart';
import '../../Presentation/modules/login/bindings/login_binding.dart';
import '../../Presentation/modules/login/views/login_view.dart';
import '../../Presentation/modules/mychats/bindings/mychats_binding.dart';
import '../../Presentation/modules/mychats/views/mychats_view.dart';
import '../../Presentation/modules/profile/bindings/profile_binding.dart';
import '../../Presentation/modules/profile/views/profile_view.dart';
import '../../Presentation/modules/request/bindings/request_binding.dart';
import '../../Presentation/modules/request/views/request_view.dart';
import '../../Presentation/modules/search/bindings/search_binding.dart';
import '../../Presentation/modules/search/views/search_view.dart';
import '../../Presentation/modules/signup/bindings/signup_binding.dart';
import '../../Presentation/modules/signup/views/signup_view.dart';
import '../../Presentation/modules/splash/bindings/splash_binding.dart';
import '../../Presentation/modules/splash/views/splash_view.dart';
import '../../Presentation/modules/call/bindings/call_binding.dart';
import '../../Presentation/modules/call/views/call_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.SIGNUP,
      page: () => SignupView(),
      binding: SignupBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.HOMEPAGES,
      page: () => const HomepagesView(),
      binding: HomepagesBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: _Paths.REQUEST,
      page: () => const RequestView(),
      binding: RequestBinding(),
    ),
    GetPage(
      name: _Paths.FRIENDS,
      page: () => const FriendsView(),
      binding: FriendsBinding(),
    ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: _Paths.MYCHATS,
      page: () => const MychatsView(),
      binding: MychatsBinding(),
    ),

    GetPage(name: _Paths.CALL, page: () => CallView(), binding: CallBinding()),
  ];
}
