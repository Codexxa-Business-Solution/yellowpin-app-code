import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_bar_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/api/auth_storage.dart';
import 'features/screen_01/splash_page.dart';
import 'features/screen_02/onboarding_1_page.dart';
import 'features/screen_03/onboarding_2_page.dart';
import 'features/screen_04/onboarding_3_page.dart';
import 'features/screen_05/sign_up_page.dart';
import 'features/screen_06/verify_page.dart';
import 'features/screen_07/sign_up_as_page.dart';
import 'features/screen_08/profile_form_page.dart';
import 'features/screen_09/location_page.dart';
import 'features/screen_10/sign_in_page.dart';
import 'features/screen_11/log_in_as_page.dart';
import 'features/screen_12/details_page.dart';
import 'features/home/home_shell_page.dart';
import 'features/applicants/applicants_page.dart';
import 'features/shortlisted/shortlisted_page.dart';
import 'features/details/job_seeker_details_page.dart';
import 'features/details/college_details_page.dart';
import 'features/details/job_details_page.dart';
import 'features/details/application_success_page.dart';
import 'features/details/applied_job_details_page.dart';
import 'features/details/job_excel_response_page.dart';
import 'features/details/job_campus_confirmation_page.dart';
import 'features/details/campus_confirmation_sent_page.dart';
import 'features/details/interview_steps_page.dart';
import 'features/full_time/full_time_jobs_page.dart';
import 'features/part_time/part_time_jobs_page.dart';
import 'features/network/student_profile_list_page.dart';
import 'features/network/institute_profile_list_page.dart';
import 'features/job_form/job_form_page.dart';
import 'features/course/course_list_page.dart';
import 'features/course/course_detail_page.dart';
import 'features/course/create_course_page.dart';
import 'features/event/event_list_page.dart';
import 'features/event/event_detail_page.dart';
import 'features/event/create_event_page.dart';
import 'features/profile_menu/profile_menu_item_page.dart';
import 'features/profile_menu/my_profile_page.dart';
import 'features/profile_menu/personal_info_page.dart';
import 'features/profile_menu/hr_edit_profile_page.dart';
import 'features/profile_menu/organisation_edit_profile_page.dart';
import 'features/profile_menu/college_info_page.dart';
import 'features/my_listing/institutes_list_page.dart';
import 'features/my_listing/job_seekers_list_page.dart';
import 'features/my_listing/applications_list_page.dart';
import 'features/my_listing/posted_jobs_list_page.dart';
import 'features/my_listing/posted_events_list_page.dart';
import 'features/notifications/notifications_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStorage.init();
  await AuthStorage.loadProfileImageUrlFromPrefs();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.headerYellow,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yellow Pin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryOrange),
        useMaterial3: true,
        appBarTheme: AppBarThemeCustom.theme,
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(builder: (_) => const SplashPage());
          case AppRoutes.onboarding1:
            return MaterialPageRoute(builder: (_) => const Onboarding1Page());
          case AppRoutes.onboarding2:
            return MaterialPageRoute(builder: (_) => const Onboarding2Page());
          case AppRoutes.onboarding3:
            return MaterialPageRoute(builder: (_) => const Onboarding3Page());
          // Sign up flow: Screen 5 → 6 → 7 → 8 → 9 → details
          case AppRoutes.signUp:
            return MaterialPageRoute(builder: (_) => const SignUpPage());
          case AppRoutes.verify:
            return MaterialPageRoute(
              builder: (_) => const VerifyPage(),
              settings: settings,
            );
          case AppRoutes.signUpAs:
            return MaterialPageRoute(builder: (_) => const SignUpAsPage(), settings: settings);
          case AppRoutes.profileForm:
            return MaterialPageRoute(builder: (_) => const ProfileFormPage(), settings: settings);
          case AppRoutes.location:
            return MaterialPageRoute(builder: (_) => const LocationPage());
          case AppRoutes.details:
            return MaterialPageRoute(builder: (_) => const DetailsPage());
          // Sign in flow: Screen 10 → 6 (Verify) → 11 → 8 → 9 → 12 (Details/Screen 13)
          case AppRoutes.signIn:
            return MaterialPageRoute(builder: (_) => const SignInPage(), settings: settings);
          case AppRoutes.logInAs:
            return MaterialPageRoute(builder: (_) => const LogInAsPage(), settings: settings);
          case AppRoutes.home:
            final tabIndex = settings.arguments is int ? settings.arguments as int : null;
            return MaterialPageRoute(
              builder: (_) => HomeShellPage(initialIndex: tabIndex),
              settings: settings,
            );
          case AppRoutes.applicants:
            return MaterialPageRoute(builder: (_) => const ApplicantsPage());
          case AppRoutes.shortlisted:
            return MaterialPageRoute(builder: (_) => const ShortlistedPage());
          case AppRoutes.jobSeekerDetails:
            return MaterialPageRoute(builder: (_) => const JobSeekerDetailsPage());
          case AppRoutes.collegeDetails:
            return MaterialPageRoute(builder: (_) => const CollegeDetailsPage());
          case AppRoutes.jobDetails:
            final jobId = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => JobDetailsPage(jobId: jobId is int ? jobId : (jobId != null ? int.tryParse(jobId.toString()) : null)),
            );
          case AppRoutes.applicationSuccess:
            return MaterialPageRoute(builder: (_) => const ApplicationSuccessPage(), settings: settings);
          case AppRoutes.appliedJobDetails:
            return MaterialPageRoute(builder: (_) => const AppliedJobDetailsPage(), settings: settings);
          case AppRoutes.jobExcelResponse:
            return MaterialPageRoute(builder: (_) => const JobExcelResponsePage(), settings: settings);
          case AppRoutes.jobCampusConfirmation:
            return MaterialPageRoute(builder: (_) => const JobCampusConfirmationPage(), settings: settings);
          case AppRoutes.campusConfirmationSent:
            return MaterialPageRoute(builder: (_) => const CampusConfirmationSentPage(), settings: settings);
          case AppRoutes.interviewSteps:
            return MaterialPageRoute(builder: (_) => const InterviewStepsPage(), settings: settings);
          case AppRoutes.fullTimeJobs:
            return MaterialPageRoute(builder: (_) => const FullTimeJobsPage());
          case AppRoutes.partTimeJobs:
            return MaterialPageRoute(builder: (_) => const PartTimeJobsPage());
          case AppRoutes.studentProfileList:
            return MaterialPageRoute(builder: (_) => const StudentProfileListPage());
          case AppRoutes.instituteProfileList:
            return MaterialPageRoute(builder: (_) => const InstituteProfileListPage());
          case AppRoutes.jobForm1:
            return MaterialPageRoute(builder: (_) => const JobFormPage(step: 1));
          case AppRoutes.jobForm2:
            return MaterialPageRoute(builder: (_) => const JobFormPage(step: 2));
          case AppRoutes.jobForm3:
            return MaterialPageRoute(builder: (_) => const JobFormPage(step: 3));
          case AppRoutes.jobForm4:
            return MaterialPageRoute(builder: (_) => const JobFormPage(step: 4));
          case AppRoutes.createJob:
            return MaterialPageRoute(builder: (_) => const JobFormPage(step: 1));
          case AppRoutes.courseList:
            return MaterialPageRoute(builder: (_) => const CourseListPage(isStandalone: true));
          case AppRoutes.courseDetail:
            final courseId = settings.arguments is int ? settings.arguments as int : null;
            return MaterialPageRoute(builder: (_) => CourseDetailPage(courseId: courseId));
          case AppRoutes.createCourse:
            return MaterialPageRoute(builder: (_) => const CreateCoursePage());
          case AppRoutes.eventList:
            final showOnlyMyEvents = settings.arguments == true;
            return MaterialPageRoute(builder: (_) => EventListPage(showOnlyMyEvents: showOnlyMyEvents));
          case AppRoutes.eventDetail:
            final eventId = settings.arguments is int ? settings.arguments as int : null;
            return MaterialPageRoute(builder: (_) => EventDetailPage(eventId: eventId));
          case AppRoutes.createEvent:
            final args = settings.arguments is Map ? settings.arguments as Map : null;
            final createEventId = args != null && args['eventId'] is int ? args['eventId'] as int : null;
            final initialEvent = args != null && args['initialEvent'] is Map
                ? Map<String, dynamic>.from(args['initialEvent'] as Map)
                : null;
            return MaterialPageRoute<bool?>(
              builder: (_) => CreateEventPage(eventId: createEventId, initialEvent: initialEvent),
            );
          case AppRoutes.profileMenu:
            return MaterialPageRoute(builder: (_) => const MyProfilePage());
          case AppRoutes.personalInfo:
            return MaterialPageRoute(builder: (_) => const PersonalInfoPage());
          case AppRoutes.hrEditProfile:
            return MaterialPageRoute(builder: (_) => const HrEditProfilePage());
          case AppRoutes.organisationEditProfile:
            return MaterialPageRoute(builder: (_) => const OrganisationEditProfilePage());
          case AppRoutes.collegeInfo:
            return MaterialPageRoute(builder: (_) => const CollegeInfoPage());
          case AppRoutes.notifications:
            return MaterialPageRoute(builder: (_) => const NotificationsPage());
          case AppRoutes.profileMenuItem:
            return MaterialPageRoute(
              builder: (_) => ProfileMenuItemPage(title: (settings.arguments as String?) ?? 'Menu Item'),
            );
          case AppRoutes.institutesList:
            return MaterialPageRoute(builder: (_) => const InstitutesListPage());
          case AppRoutes.jobSeekersList:
            return MaterialPageRoute(builder: (_) => const JobSeekersListPage());
          case AppRoutes.applicationsList:
            return MaterialPageRoute(builder: (_) => const ApplicationsListPage());
          case AppRoutes.postedJobsList:
            return MaterialPageRoute(builder: (_) => const PostedJobsListPage());
          case AppRoutes.postedEventsList:
            return MaterialPageRoute(builder: (_) => const PostedEventsListPage());
          default:
            return MaterialPageRoute(builder: (_) => const SplashPage());
        }
      },
    );
  }
}
