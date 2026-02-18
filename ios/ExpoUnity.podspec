require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

# Resolve the Unity build artifacts directory.
# Pod::Config.instance.project_root points to the ios/ folder (where the Podfile lives),
# so we go one level up (..) to reach the React Native project root, then into unity/builds/ios/.
# Override with EXPO_UNITY_PATH environment variable.
rn_project_root = File.expand_path('..', Pod::Config.instance.project_root.to_s)
unity_ios_dir = ENV['EXPO_UNITY_PATH'] || File.join(rn_project_root, 'unity', 'builds', 'ios')

Pod::Spec.new do |s|
  s.name           = 'ExpoUnity'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platforms      = { :ios => '15.1' }
  s.source         = { :git => package['repository']['url'], :tag => "v#{s.version}" }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  s.source_files = '**/*.{h,m,mm,swift}'
  s.exclude_files = 'UnityFramework.framework/**/*'

  # Copy all Unity build artifacts into the pod at install time
  s.prepare_command = <<-CMD
    if [ -d "#{unity_ios_dir}" ]; then
      cp -Rn "#{unity_ios_dir}/." . 2>/dev/null || true
    fi
  CMD

  if File.exist?(File.join(unity_ios_dir, 'UnityFramework.framework'))
    s.vendored_frameworks = 'UnityFramework.framework'
  end

  a_files = Dir.glob(File.join(unity_ios_dir, '*.a')).map { |f| File.basename(f) }
  s.vendored_libraries = a_files unless a_files.empty?

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => [
      '"${PODS_TARGET_SRCROOT}/UnityFramework.framework/Headers"',
      "\"#{unity_ios_dir}/UnityFramework.framework/Headers\""
    ].join(' '),
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'UNITY_FRAMEWORK=1',
    'ENABLE_BITCODE' => 'NO'
  }

  s.user_target_xcconfig = {
    'ENABLE_BITCODE' => 'NO'
  }
end
