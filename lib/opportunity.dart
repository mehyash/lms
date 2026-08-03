import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// OPPORTUNITY MODEL
/// ---------------------------------------------------------------------
/// Shared data shape for both:
///  - the short "Recommended Opportunities" preview on the Home Screen
///  - the full Program Listing screen (Available / Applied / Completed)
///
/// Frontend-only for now — this will later be populated from the
/// backend response instead of the dummy lists below.
/// ---------------------------------------------------------------------

enum ProgramStatus { available, applied, completed }

/// Whether a program is paid or unpaid — kept separate from the
/// scholarship display string so the Program Details screen can show
/// a clear label without parsing "$0" / "$1,000" style strings.
enum CompensationType { paid, unpaid }

/// Remote vs on-site delivery mode for a program.
enum WorkMode { remote, onsite, hybrid }

class Opportunity {
  final int? dbId; // Supabase int8 ID
  final String name;
  final String category;
  final String scholarship;
  final IconData icon;
  final Color iconBackground;
  final List<IconData> skillIcons;
  final int extraSkillsCount; // e.g. the "2+" badge in the screenshot
  final ProgramStatus status;
  final double? progress; // 0.0 - 1.0, only meaningful for "applied"

  // -------------------------------------------------------------
  // PROGRAM DETAILS FIELDS
  // All optional with sensible defaults so existing dummy data
  // above keeps compiling unchanged. Populated per-program below.
  // -------------------------------------------------------------
  final String description;
  final String hiredBy;
  final String sponsoredBy;
  final String domain;
  final List<String> roles;
  final CompensationType compensationType;
  final String fee; // e.g. "Free" or "$49 one-time"
  final WorkMode workMode;
  final List<String> rewardsAndBadges;
  final String startDate; // display string, e.g. "Aug 18, 2026"
  final String duration; // display string, e.g. "6 weeks"
  final List<String> timeline; // ordered milestone labels
  final String applyDeadline;
  final List<String> skillsLearnt;
  final List<String> qualifications; // eligibility / requirements
  final String currentModule; // for in-progress programs
  final int weeksCompleted;
  final int totalWeeks;
  final String? curriculumUrl;

  const Opportunity({
    this.dbId,
    required this.name,
    required this.category,
    required this.scholarship,
    required this.icon,
    required this.iconBackground,
    required this.skillIcons,
    this.extraSkillsCount = 0,
    required this.status,
    this.progress,
    this.description = 'No description available yet.',
    this.hiredBy = 'Excelerate Partner Organization',
    this.sponsoredBy = 'Excelerate',
    this.domain = 'General',
    this.roles = const [],
    this.compensationType = CompensationType.unpaid,
    this.fee = 'Free',
    this.workMode = WorkMode.remote,
    this.rewardsAndBadges = const [],
    this.startDate = 'TBA',
    this.duration = 'TBA',
    this.timeline = const [],
    this.applyDeadline = 'TBA',
    this.skillsLearnt = const [],
    this.qualifications = const [],
    this.currentModule = '',
    this.weeksCompleted = 0,
    this.totalWeeks = 0,
    this.curriculumUrl,
  });
}

/// Dummy dataset standing in for the backend response (next week's work).
final List<Opportunity> dummyOpportunities = [
  Opportunity(
    name: 'Sustainability, Technology & Environmental Systems Course',
    category: 'Power Skill Courses',
    scholarship: '\$50',
    icon: Icons.eco_outlined,
    iconBackground: const Color(0xFF4B5563),
    skillIcons: const [Icons.settings, Icons.lightbulb_outline, Icons.android],
    status: ProgramStatus.available,
    description:
        'A self-paced power skill course covering the fundamentals of '
        'sustainable technology and environmental systems, blending '
        'lecture content with real-world case studies.',
    hiredBy: 'GreenFuture Foundation',
    sponsoredBy: 'Excelerate Power Skills',
    domain: 'Sustainability & Environment',
    roles: const ['Course Participant'],
    compensationType: CompensationType.unpaid,
    fee: 'Free',
    workMode: WorkMode.remote,
    rewardsAndBadges: const ['Certificate of Completion', 'Green Tech Badge'],
    startDate: 'Aug 4, 2026',
    duration: '4 weeks',
    timeline: const ['Enrollment', 'Modules 1–3', 'Final Project', 'Certification'],
    applyDeadline: 'Aug 1, 2026',
    skillsLearnt: const ['Sustainable Design', 'Environmental Systems', 'Green Tech Tools'],
    qualifications: const ['Open to all learners', 'Basic English proficiency'],
  ),
  Opportunity(
    name: 'Data Visualization Associate Early Remote Internship',
    category: 'Global Internships',
    scholarship: '\$1,000',
    icon: Icons.bar_chart_rounded,
    iconBackground: const Color(0xFFE0356B),
    skillIcons: const [Icons.volume_up, Icons.handshake_outlined],
    extraSkillsCount: 2,
    status: ProgramStatus.applied,
    progress: 0.4,
    description:
        'Work alongside a remote data team to build interactive dashboards '
        'and visual reports for real client datasets, with weekly mentor '
        'check-ins and structured feedback.',
    hiredBy: 'InsightWorks Analytics',
    sponsoredBy: 'Excelerate Global Internships',
    domain: 'Data Analytics',
    roles: const ['Data Visualization Associate'],
    compensationType: CompensationType.paid,
    fee: 'Free',
    workMode: WorkMode.remote,
    rewardsAndBadges: const ['Internship Certificate', 'Letter of Recommendation'],
    startDate: 'Jun 2, 2026',
    duration: '6 weeks',
    timeline: const ['Onboarding', 'Module 1: Data Cleaning', 'Module 2: Dashboards', 'Final Presentation'],
    applyDeadline: 'May 20, 2026',
    skillsLearnt: const ['Data Visualization', 'Dashboarding Tools', 'Client Communication'],
    qualifications: const ['Basic Excel/SQL knowledge', 'Currently enrolled student'],
    currentModule: 'Module 2: Dashboards',
    weeksCompleted: 2,
    totalWeeks: 6,
  ),
  Opportunity(
    name: 'Project Management Associate Early Remote Internship',
    category: 'Global Internships',
    scholarship: '\$1,000',
    icon: Icons.groups_2_outlined,
    iconBackground: const Color(0xFF29ABE2),
    skillIcons: const [Icons.volume_up, Icons.handshake_outlined, Icons.lightbulb_outline],
    extraSkillsCount: 2,
    status: ProgramStatus.applied,
    progress: 0.75,
    description:
        'Support cross-functional teams with sprint planning, stakeholder '
        'communication, and delivery tracking on live remote projects, '
        'gaining hands-on experience with agile workflows.',
    hiredBy: 'Vantage Global Partners',
    sponsoredBy: 'Excelerate Global Internships',
    domain: 'Project Management',
    roles: const ['Project Management Associate'],
    compensationType: CompensationType.paid,
    fee: 'Free',
    workMode: WorkMode.remote,
    rewardsAndBadges: const ['Internship Certificate', 'Agile Fundamentals Badge'],
    startDate: 'May 5, 2026',
    duration: '6 weeks',
    timeline: const ['Onboarding', 'Sprint 1', 'Sprint 2', 'Wrap-up & Review'],
    applyDeadline: 'Apr 20, 2026',
    skillsLearnt: const ['Agile/Scrum', 'Stakeholder Management', 'Task Tracking Tools'],
    qualifications: const ['Strong communication skills', 'Currently enrolled student'],
    currentModule: 'Frontend Architecture',
    weeksCompleted: 3,
    totalWeeks: 6,
  ),
  Opportunity(
    name: 'Prompt Engineering Research and Integration Remote Internship',
    category: 'Global Internships',
    scholarship: '\$0',
    icon: Icons.travel_explore,
    iconBackground: const Color(0xFF0EA5A4),
    skillIcons: const [Icons.settings, Icons.lightbulb_outline, Icons.volume_up],
    extraSkillsCount: 4,
    status: ProgramStatus.available,
    description:
        'Research and integrate prompt engineering techniques into real '
        'product workflows, experimenting with LLM tooling under the '
        'guidance of an industry mentor.',
    hiredBy: 'Nimbus AI Labs',
    sponsoredBy: 'Excelerate Global Internships',
    domain: 'Artificial Intelligence',
    roles: const ['Prompt Engineering Intern'],
    compensationType: CompensationType.unpaid,
    fee: 'Free',
    workMode: WorkMode.remote,
    rewardsAndBadges: const ['Internship Certificate', 'AI Research Badge'],
    startDate: 'Sep 1, 2026',
    duration: '5 weeks',
    timeline: const ['Onboarding', 'Research Phase', 'Integration Phase', 'Final Demo'],
    applyDeadline: 'Aug 15, 2026',
    skillsLearnt: const ['Prompt Design', 'LLM Evaluation', 'API Integration'],
    qualifications: const ['Interest in AI/ML', 'Basic Python knowledge'],
  ),
  Opportunity(
    name: 'UI/UX Design Fundamentals Course',
    category: 'Power Skill Courses',
    scholarship: '\$25',
    icon: Icons.brush_outlined,
    iconBackground: const Color(0xFF9333EA),
    skillIcons: const [Icons.palette_outlined, Icons.design_services_outlined],
    status: ProgramStatus.completed,
    progress: 1.0,
  ),
  Opportunity(
    name: 'Digital Marketing Bootcamp',
    category: 'Global Internships',
    scholarship: '\$500',
    icon: Icons.campaign_outlined,
    iconBackground: const Color(0xFFF59E0B),
    skillIcons: const [Icons.trending_up, Icons.share_outlined],
    status: ProgramStatus.completed,
    progress: 1.0,
  ),
];
