import 'package:get/get.dart';

import '../../modules/auth/login_view.dart';
import '../../modules/auth/register_view.dart';
import '../../modules/discover/search_view.dart';
import '../../modules/feed/home_view.dart';
import '../../modules/post/create_post_view.dart';
import '../../modules/post/post_detail_view.dart';
import '../../modules/profile/edit_profile_view.dart';
import '../../modules/profile/profile_view.dart';
import '../../modules/stories/create_story_view.dart';
import '../../modules/stories/story_viewer_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final routes = <GetPage>[
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView()),
    GetPage(name: AppRoutes.home, page: () => const HomeView()),
    GetPage(name: AppRoutes.createPost, page: () => const CreatePostView()),
    GetPage(name: AppRoutes.postDetail, page: () => const PostDetailView()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileView()),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileView()),
    GetPage(name: AppRoutes.search, page: () => const SearchView()),
    GetPage(name: AppRoutes.createStory, page: () => const CreateStoryView()),
    GetPage(name: AppRoutes.storyViewer, page: () => const StoryViewerView()),
  ];
}
