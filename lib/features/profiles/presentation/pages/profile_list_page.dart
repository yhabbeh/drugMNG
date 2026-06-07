import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/core/router/app_routes.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/presentation/bloc/profiles_bloc.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';

class ProfileListPage extends StatelessWidget {
  const ProfileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver Profiles')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.profileForm),
        child: const Icon(Icons.add),
      ),
      body: BlocListener<ProfilesBloc, ProfilesState>(
        listener: (context, state) {
          if (state is ProfilesLoaded && state.profiles.isNotEmpty) {
            final activeState = context.read<ActiveProfileCubit>().state;
            if (activeState is ActiveProfileEmpty) {
              context.read<ActiveProfileCubit>().selectProfile(state.profiles.first);
            }
          }
        },
        child: BlocBuilder<ProfilesBloc, ProfilesState>(
          builder: (context, state) {
            return switch (state) {
              ProfilesInitial() => const Center(child: CircularProgressIndicator()),
              ProfilesLoading() => const Center(child: CircularProgressIndicator()),
              ProfilesLoaded(:final profiles, isLoading: true) => _buildBody(context, profiles, isLoading: true),
              ProfilesLoaded(:final profiles) => _buildBody(context, profiles),
              ProfilesError(:final failure) => Center(child: Text('Error: ${failure.message}')),
            };
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<CaregiverProfile> profiles, {bool isLoading = false}) {
    if (profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No profiles yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => context.push(AppRoutes.profileForm),
              child: const Text('Add Profile'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<ActiveProfileCubit, ActiveProfileState>(
      builder: (context, activeState) {
        final activeId = activeState is ActiveProfileSelected ? activeState.profile.id : null;

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final isActive = profile.id == activeId;
                return _ProfileCard(
                  profile: profile,
                  isActive: isActive,
                  onTap: () => context.read<ActiveProfileCubit>().selectProfile(profile),
                  onEdit: () => context.push(AppRoutes.profileForm, extra: profile),
                  onDelete: () => _confirmDelete(context, profile),
                );
              },
            ),
            if (isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CaregiverProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${profile.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final activeState = context.read<ActiveProfileCubit>().state;
              if (activeState is ActiveProfileSelected && activeState.profile.id == profile.id) {
                context.read<ActiveProfileCubit>().clearProfile();
              }
              context.read<ProfilesBloc>().add(ProfileDeleted(profile.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

final class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CaregiverProfile profile;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = profile.color != null ? Color(profile.color!) : Colors.teal;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isActive ? 4 : 1,
      shape: isActive
          ? RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        selected: isActive,
        leading: CircleAvatar(
          backgroundColor: color,
          child: profile.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Text(
                      profile.displayName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
              : Text(
                  profile.displayName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
        title: Row(
          children: [
            Text(profile.displayName),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(profile.relationship.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
