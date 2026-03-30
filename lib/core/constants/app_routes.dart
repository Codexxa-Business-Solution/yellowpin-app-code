/// Named routes. Screens 14-71.
class AppRoutes {
  AppRoutes._();

  // Auth (1-13). Sign up flow: Screen 5 → 6 → 7 → 8 → 9. Sign in flow: Screen 10 → 6 → 11 → 8 → 9 → 12 (Details/Screen 13).
  static const String splash = '/';
  static const String onboarding1 = '/onboarding-1';
  static const String onboarding2 = '/onboarding-2';
  static const String onboarding3 = '/onboarding-3';
  static const String signUp = '/sign-up';           // Screen 5
  static const String verify = '/verify';            // Screen 6 (shared)
  static const String signUpAs = '/sign-up-as';      // Screen 7
  static const String profileForm = '/profile-form'; // Screen 8 (shared)
  static const String location = '/location';        // Screen 9 (shared)
  static const String details = '/details';          // Screen 12 / 13 (shared)
  static const String signIn = '/sign-in';           // Screen 10
  static const String logInAs = '/log-in-as';        // Screen 11

  // Home shell (14, 30, 35, 44, 52) — tabs: 0=My Jobs, 1=Network, 2=Home, 3=Course, 4=Event
  static const String home = '/home';
  static const String applicants = '/applicants';
  static const String shortlisted = '/shortlisted';
  static const String jobSeekerDetails = '/job-seeker-details';
  static const String collegeDetails = '/college-details';
  static const String fullTimeJobs = '/full-time-jobs';
  static const String partTimeJobs = '/part-time-jobs';

  // My Jobs 30-34
  static const String myJobs = '/my-jobs';
  static const String jobDetails = '/job-details';
  static const String createJob = '/create-job';
  static const String jobForm1 = '/job-form-1';
  static const String jobForm2 = '/job-form-2';
  static const String jobForm3 = '/job-form-3';
  static const String jobForm4 = '/job-form-4';

  // Network 35-43
  static const String networkPopup = '/network-popup';
  static const String studentProfileList = '/student-profile-list';
  static const String instituteProfileList = '/institute-profile-list';

  // Course 44-51
  static const String courseList = '/course-list';
  static const String courseDetail = '/course-detail';
  static const String createCourse = '/create-course';

  // Event 52-60
  static const String eventList = '/event-list';
  static const String eventDetail = '/event-detail';
  static const String createEvent = '/create-event';

  // Profile menu 61-71, My Listing
  static const String profileMenu = '/profile-menu';
  static const String collegeInfo = '/college-info';
  static const String notifications = '/notifications';
  static const String profileMenuItem = '/profile-menu-item';
  /// Job seeker / institute: full personal info form (profile completion).
  static const String personalInfo = '/personal-info';
  static const String hrEditProfile = '/hr-edit-profile';
  static const String organisationEditProfile = '/organisation-edit-profile';
  static const String institutesList = '/institutes-list';
  static const String jobSeekersList = '/job-seekers-list';
  static const String applicationsList = '/applications-list';
  static const String postedJobsList = '/posted-jobs-list';
  static const String postedEventsList = '/posted-events-list';
  static const String applicationSuccess = '/application-success';
  static const String appliedJobDetails = '/applied-job-details';
  /// Institute: Excel sheet with HR/Org response (student rows + status).
  static const String jobExcelResponse = '/job-excel-response';
  /// Institute: campus date confirmation after Excel selection.
  static const String jobCampusConfirmation = '/job-campus-confirmation';
  /// Institute: success after campus confirmation submitted.
  static const String campusConfirmationSent = '/campus-confirmation-sent';
  /// Institute / HR: multi-step interview rounds with candidate table.
  static const String interviewSteps = '/interview-steps';
}
