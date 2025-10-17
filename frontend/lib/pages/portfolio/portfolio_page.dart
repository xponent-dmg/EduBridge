import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/portfolio_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/portfolio/portfolio_card.dart';
import '../../widgets/portfolio/portfolio_stats.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key, required this.userId});
  final dynamic userId;

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPortfolio());
  }

  Future<void> _loadPortfolio() async {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    final userId = widget.userId?.toString();
    if (userId == null || userId.isEmpty || userId == 'null') {
      portfolioProvider.clearError(); // no-op but ensures listeners are aware state is not loading endlessly
      return;
    }
    await portfolioProvider.loadPortfolio(userId);
  }

  @override
  Widget build(BuildContext context) {
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isCurrentUser = widget.userId.toString() == authProvider.currentUser?.userId;
    final userRole = authProvider.currentUser?.role ?? 'student';
    final isCompany = userRole == 'company';
    final isStudent = userRole == 'student';

    // Determine if this is a company viewing a student's portfolio
    final isCompanyViewingStudentPortfolio = isCompany && !isCurrentUser;

    return AppScaffold(
      title: isCurrentUser ? 'My Portfolio' : 'Portfolio',
      currentIndex: isStudent ? 3 : -1, // Only students have portfolio in bottom nav
      body: RefreshIndicator(
        onRefresh: _loadPortfolio,
        child: _buildContent(portfolioProvider, isCompanyViewingStudentPortfolio),
      ),
    );
  }

  Widget _buildContent(PortfolioProvider portfolioProvider, bool isCompanyViewingStudentPortfolio) {
    switch (portfolioProvider.status) {
      case PortfolioLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case PortfolioLoadStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                portfolioProvider.errorMessage?.isNotEmpty == true
                    ? 'Failed to load portfolio: ${portfolioProvider.errorMessage}'
                    : 'No portfolio available yet',
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadPortfolio, child: const Text('Try Again')),
            ],
          ),
        );

      case PortfolioLoadStatus.loaded:
        final entries = portfolioProvider.entries;
        if (entries.isEmpty) {
          return _buildEmptyState(isCompanyViewingStudentPortfolio);
        }
        return _buildPortfolioList(entries, isCompanyViewingStudentPortfolio);

      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildEmptyState(bool isCompanyViewingStudentPortfolio) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Portfolio is Empty', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              isCompanyViewingStudentPortfolio
                  ? 'This student has not added any projects to their portfolio yet'
                  : 'Complete tasks and add submissions to build your portfolio',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            if (!isCompanyViewingStudentPortfolio)
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/tasks'),
                icon: const Icon(Icons.search),
                label: const Text('Find Tasks'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioList(List<PortfolioEntryModel> entries, bool isCompanyViewingStudentPortfolio) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'Student';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats at the top
        PortfolioStats(entries: entries),

        // Header with action button for students
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isCompanyViewingStudentPortfolio ? '$userName\'s Portfolio' : 'My Portfolio Entries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (!isCompanyViewingStudentPortfolio)
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/submissions'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Entry'),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Portfolio entries
        ...entries.map(
          (entry) => PortfolioCard(
            entry: entry,
            onTap: () => _showPortfolioEntryDetails(entry),
            isCompanyView: isCompanyViewingStudentPortfolio,
          ),
        ),
      ],
    );
  }

  void _showPortfolioEntryDetails(PortfolioEntryModel entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  entry.task.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.task.domains
                      .map(
                        (domain) => Chip(
                          label: Text(domain),
                          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Task Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(entry.task.description),
                const SizedBox(height: 16),
                if (entry.submission.grade != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Grade',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: entry.submission.grade != null ? _getGradeColor(entry.submission.grade!) : Colors.grey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          entry.submission.grade != null ? '${entry.submission.grade}%' : 'N/A',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
                if (entry.submission.feedback != null && entry.submission.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Feedback',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(entry.submission.feedback!),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGradeColor(int grade) {
    if (grade >= 80) {
      return Colors.green;
    } else if (grade >= 60) {
      return Colors.blue;
    } else if (grade >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
