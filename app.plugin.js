const { withXcodeProject } = require('@expo/config-plugins');
const path = require('path');
const fs = require('fs');

/**
 * Expo Config Plugin for @dolami-inc/react-native-expo-unity.
 *
 * - Injects required Xcode build settings (bitcode, C++17)
 * - Embeds UnityFramework.framework into the app bundle so it's
 *   available at runtime (Unity ships as a dynamic framework)
 *
 * @param {object} config - Expo config
 * @param {{ unityPath?: string }} options
 *   unityPath — absolute path to the Unity iOS build artifacts directory.
 *   Defaults to `<projectRoot>/unity/builds/ios`.
 *   Can also be set via the EXPO_UNITY_PATH environment variable.
 */
const withExpoUnity = (config, options = {}) => {
  return withXcodeProject(config, (config) => {
    const xcodeProject = config.modResults;
    const projectRoot = config.modRequest.projectRoot;

    // Resolve actual filesystem path for the Unity build artifacts.
    const unityPath =
      options.unityPath ||
      process.env.EXPO_UNITY_PATH ||
      path.join(projectRoot, 'unity', 'builds', 'ios');

    // -- Build settings --
    const configurations = xcodeProject.pbxXCBuildConfigurationSection();
    for (const key of Object.keys(configurations)) {
      const configuration = configurations[key];
      if (typeof configuration !== 'object' || !configuration.buildSettings) {
        continue;
      }

      const settings = configuration.buildSettings;

      // Unity as a Library does not support bitcode.
      settings['ENABLE_BITCODE'] = 'NO';

      // Unity headers require C++17.
      // Must be quoted — '+' causes CocoaPods' plist parser to fail if unquoted.
      settings['CLANG_CXX_LANGUAGE_STANDARD'] = '"c++17"';
    }

    // -- Embed UnityFramework --
    // UnityFramework is a dynamic framework. It must be embedded (copied) into
    // the app bundle's Frameworks/ directory, otherwise dyld fails at launch.
    const frameworkPath = path.join(unityPath, 'UnityFramework.framework');
    if (fs.existsSync(frameworkPath)) {
      xcodeProject.addFramework(frameworkPath, {
        customFramework: true,
        embed: true,
        sign: true,
      });
    }

    return config;
  });
};

module.exports = withExpoUnity;
