import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:spot/components/gradient_button.dart';
import 'package:spot/models/profile.dart';
import 'package:spot/utils/constants.dart';
import 'package:spot/components/video_list.dart';
import 'package:spot/cubits/profile/profile_cubit.dart';
import 'package:spot/cubits/videos/videos_cubit.dart';
import 'package:spot/pages/edit_profile_page.dart';
import 'package:spot/repositories/repository.dart';
import 'package:spot/utils/functions.dart';

import 'profile_image.dart';

class UserProfile extends StatelessWidget {
  UserProfile({
    Key? key,
    required String userId,
  })  : _userId = userId,
        super(key: key);

  final String _userId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          BlocProvider<ProfileCubit>(
            create: (context) => ProfileCubit(
              repository: RepositoryProvider.of<Repository>(context),
            )..loadProfile(_userId),
            child: const _Profile(),
          ),
          BlocProvider<VideosCubit>(
            create: (context) => VideosCubit(
                repository: RepositoryProvider.of<Repository>(context))
              ..loadFromUid(_userId),
            child: const _UserPosts(),
          ),
        ],
      ),
    );
  }
}

class _UserPosts extends StatelessWidget {
  const _UserPosts({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideosCubit, VideosState>(
      builder: (context, state) {
        if (state is VideosInitial) {
          return preloader;
        } else if (state is VideosLoaded) {
          final videos = state.videos;
          return VideoList(videos: videos);
        } else if (state is VideosError) {
          return const Center(
            child: Text('Something went wrong. Please reopen the app. '),
          );
        }
        throw UnimplementedError();
      },
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(builder: (context, state) {
      if (state is ProfileLoading) {
        return preloader;
      } else if (state is ProfileNotFound) {
        return const Text('Profile not found');
      } else if (state is ProfileLoaded) {
        final profile = state.profile;

        /// Used to determine if the
        final userId = RepositoryProvider.of<Repository>(context).userId;
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 31,
            horizontal: 19,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ProfileImage(
                    size: 120,
                    imageUrl: profile.imageUrl,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 17),
                        if (userId == profile.id)
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(EditProfilePage.route(
                                  isCreatingAccount: false));
                            },
                            icon: const Icon(
                              FeatherIcons.edit2,
                              size: 18,
                            ),
                            label: const Text('Edit Profile'),
                          )
                        else
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _followButton(
                              profile: profile,
                              context: context,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (profile.description != null) ...[
                const SizedBox(height: 16),
                Text(profile.description!,
                    style: const TextStyle(fontSize: 16)),
              ]
            ],
          ),
        );
      } else if (state is ProfileError) {
        return const Center(
          child: Text('Error occured while loading profile'),
        );
      }
      throw UnimplementedError(
          'Unimplemented state in _Profile of user_profile.dart');
    });
  }

  Widget _followButton({
    required Profile profile,
    required BuildContext context,
  }) {
    return GradientButton(
      decoration: profile.isFollowing
          ? const BoxDecoration(gradient: redOrangeGradient)
          : null,
      onPressed: () {
        AuthRequired.action(context, action: () {
          if (profile.isFollowing) {
            BlocProvider.of<ProfileCubit>(context).unfollow(profile.id);
          } else {
            BlocProvider.of<ProfileCubit>(context).follow(profile.id);
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            profile.isFollowing
                ? FeatherIcons.userCheck
                : FeatherIcons.userPlus,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(profile.isFollowing ? 'Following' : 'Follow'),
        ],
      ),
    );
  }
}
