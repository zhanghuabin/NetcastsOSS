import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:screenshots/config.dart';
import 'package:screenshots/capture_screen.dart';
import 'package:test/test.dart';

void main() {
  final Map<dynamic, dynamic> config = Config().config;

  group('Netcasts OSS App', () {
    // First, define the Finders. We can use these to locate Widgets from the
    // test suite. Note: the Strings provided to the `byValueKey` method must
    // be the same as the Strings we used for the Keys in step 1.
    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests
    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await Future<void>.delayed(const Duration(milliseconds: 3000));
    });

    // Close the connection to the driver after the tests have completed
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('check flutter health driver', () async {
      final Health health = await driver.checkHealth();
      print(health.status);
    });

    test('home', () async {
      final SerializableFinder homeFinder = find.text('Science');
      await driver.waitFor(homeFinder);
      await screenshot(driver, config, 'home');

      final SerializableFinder drawerButton = find.byTooltip('Open navigation menu');
      await driver.tap(drawerButton);
      await screenshot(driver, config, 'drawer');

      final SerializableFinder exploreMenuOption = find.text('Explore');
      await driver.tap(exploreMenuOption);
      await screenshot(driver, config, 'explore');

      final SerializableFinder podcastSearchField = find.byValueKey('podcastSearch');
      await driver.tap(podcastSearchField);
      await driver.enterText('infinite monkey');
      await driver.waitFor(find.text('infinite monkey'));
      final SerializableFinder podcastSearchButton = find.byTooltip('Search for Podcasts');
      await driver.tap(podcastSearchButton);
      final SerializableFinder podcastResult = find.text('The Infinite Monkey Cage');
      await driver.waitFor(podcastResult);
      await screenshot(driver, config, 'explore-with-results');

      await driver.tap(podcastResult);
      await driver.waitFor(podcastResult);
      await screenshot(driver, config, 'podcast');

      final SerializableFinder episodesTab = find.text('Episodes');
      await driver.tap(episodesTab);
      await screenshot(driver, config, 'episodes');

      final SerializableFinder episode = find.text('How We Measure the Universe');
      await driver.tap(episode);
      await screenshot(driver, config, 'episode');

      await driver.tap(find.pageBack());
      await driver.tap(find.pageBack());
      await driver.tap(find.pageBack());
      //await driver.tap(drawerButton);

      final SerializableFinder settingsMenuOption = find.text('Settings');
      await driver.tap(settingsMenuOption);
      await screenshot(driver, config, 'settings');
    });
  });
}
