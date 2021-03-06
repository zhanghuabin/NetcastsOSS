// ignore_for_file: always_specify_types
import 'dart:async';

import 'package:hear2learn/app.dart';
import 'package:hear2learn/services/connectors/elastic.dart';
import 'package:hear2learn/models/podcast.dart';
import 'package:hear2learn/models/podcast_subscription.dart';

const String PODCAST_TYPE = 'podcast';

Future<List<Podcast>> getSubscriptions() {
  final App app = App();
  final PodcastSubscriptionBean subscriptionModel = app.models['podcast_subscription'];

  return subscriptionModel.findWhere(subscriptionModel.isSubscribed.eq(true)).then((response) {
    return Future.wait(response.map((subscription) => Future.value(subscription.getPodcastFromDetails())));
  });
}

Future<List<Podcast>> searchPodcastsByGenre(String genreId) async {
  final App app = App();
  final client = app.elasticClient;

  final query = {
    'query': {
      'bool': {
        'filter': [
          { 'exists': { 'field': 'feed' } },
          {
            'term': {
              'primary_genre.id': genreId,
            }
          }
        ]
      }
    },
    'sort': [
      'popularity',
    ],
  };
  return client.search(
    type: PODCAST_TYPE,
    body: query,
  ).then((response) => toPodcasts(response));
}

Future<List<Podcast>> searchPodcastsByTextQuery(String textQuery, { int pageSize = 10, int page = 0 }) async {
  final App app = App();
  final client = app.elasticClient;

  final query = {
    'from': page * pageSize,
    'query': {
      'bool': {
        'filter': [
          { 'exists': { 'field': 'feed' } },
        ],
        'minimum_should_match': 1,
        'should': [
          {
            'multi_match': {
              'fields': [
                'name^16',
                'artist.name^8',
                'genre^8',
                'description',
              ],
              'operator': 'and',
              'query': textQuery
            }
          }
        ],
      }
    },
    'size': pageSize,
  };
  return client.search(
    body: query,
    type: PODCAST_TYPE,
  ).then((response) => toPodcasts(response));
}

Future<void> subscribeToPodcast(Podcast podcast) async {
  final App app = App();
  final PodcastSubscriptionBean subscriptionModel = app.models['podcast_subscription'];
  final PodcastSubscription newSubscription = PodcastSubscription(
    created: DateTime.now(),
    details: podcast.toJson(),
    isSubscribed: true,
    podcastId: podcast.id,
    podcastUrl: podcast.feed,
  );
  await subscriptionModel.insert(newSubscription);
}

Future<void> unsubscribeFromPodcast(Podcast podcast) async {
  final App app = App();
  final PodcastSubscriptionBean subscriptionModel = app.models['podcast_subscription'];
  await subscriptionModel.removeWhere(subscriptionModel.podcastUrl.eq(podcast.feed));
}

List<Podcast> toPodcasts(ElasticsearchResponse response) {
  return response.hits.map((hit) => Podcast.fromJson(hit.source)).toList();
}
