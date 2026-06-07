import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:drug/core/di/injection_container.dart';
import 'package:drug/core/notifications/notification_scheduler.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drug/features/settings/domain/settings_state.dart';
import 'package:drug/features/settings/presentation/cubit/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (!state.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: const [
              _AccountSection(),
              _SectionHeader('Appearance'),
              _ThemeModeTile(),
              _SectionHeader('Notifications'),
              _NotificationsEnabledTile(),
              _SectionHeader('Inventory'),
              _ExpirationWarningTile(),
              _SectionHeader('Data'),
              _ClearLocalDataTile(),
              _SectionHeader('About'),
              _AboutTile(),
            ],
          );
        },
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

// ── Account ───────────────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _Avatar(user: user),
                const SizedBox(width: 16),
                Expanded(child: _UserInfo(user: user)),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign out',
                  onPressed: () => _confirmSignOut(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final photoUrl = user?.photoUrl;
    final initial = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName[0].toUpperCase()
        : '?';

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: cs.primaryContainer,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {},
        child: Text(
          initial,
          style: TextStyle(color: cs.onPrimaryContainer),
        ),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: cs.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  const _UserInfo({required this.user});

  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Text(
        'Not signed in',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          user!.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          user!.isAnonymous
              ? 'Guest account'
              : (user!.email ?? 'No email'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Appearance ────────────────────────────────────────────────────────────────

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) => a.themeMode != b.themeMode,
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(state.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickThemeMode(context, state.themeMode),
          ),
        );
      },
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Follow system',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  void _pickThemeMode(BuildContext context, ThemeMode current) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsCubit>().setThemeMode(value);
                Navigator.of(ctx).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(_themeLabel(mode)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notifications ─────────────────────────────────────────────────────────────

class _NotificationsEnabledTile extends StatelessWidget {
  const _NotificationsEnabledTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) => a.notificationsEnabled != b.notificationsEnabled,
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Dose reminders'),
            subtitle: const Text(
              'Receive notifications when a dose is due',
            ),
            value: state.notificationsEnabled,
            onChanged: (value) async {
              final cubit = context.read<SettingsCubit>();
              final messenger = ScaffoldMessenger.of(context);
              await cubit.setNotificationsEnabled(value);
              if (!value) {
                await _cancelAll(messenger);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _cancelAll(ScaffoldMessengerState messenger) async {
    try {
      await sl<NotificationScheduler>().cancelAllForProfile('');
      messenger.showSnackBar(
        const SnackBar(content: Text('All scheduled reminders cleared')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to clear reminders: $e')),
      );
    }
  }
}

// ── Inventory ─────────────────────────────────────────────────────────────────

class _ExpirationWarningTile extends StatelessWidget {
  const _ExpirationWarningTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) => a.expirationWarningDays != b.expirationWarningDays,
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Expiration warning window'),
            subtitle: Text('Warn ${state.expirationWarningDays} days before expiry'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickDays(context, state.expirationWarningDays),
          ),
        );
      },
    );
  }

  void _pickDays(BuildContext context, int current) {
    const options = [7, 14, 30, 60, 90, 180];
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Warn me before expiry'),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsCubit>().setExpirationWarningDays(value);
                Navigator.of(ctx).pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final days in options)
                  RadioListTile<int>(
                    value: days,
                    title: Text('$days days'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _ClearLocalDataTile extends StatelessWidget {
  const _ClearLocalDataTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.delete_forever_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          'Clear local data',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        subtitle: const Text('Removes cached medications, schedules, and profiles'),
        onTap: () => _confirmClear(context),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This will remove all cached data on this device. '
          'Your data on the server is not affected. The app will reload.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await context.read<SettingsCubit>().clearLocalData();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Local data cleared')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to clear data: $e')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ── About ─────────────────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '—';
          final build = snapshot.data?.buildNumber ?? '—';
          return ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            subtitle: Text('$version ($build)'),
          );
        },
      ),
    );
  }
}
