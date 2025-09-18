source "https://rubygems.org"

gem "fastlane"
gem "fastlane-plugin-json"
gem "dotenv"
gem "xcov"
gem "xcpretty-json-formatter"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
