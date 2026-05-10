cask "notificli-local" do
  version "1.4.1"
  sha256 "4f5b90d661773cdae68829c5501bbe092c8722381bbf350c85a095e03e968de1" # SHA of your local NotifiCLI.dmg

  # Points to your local file for testing
  url "file://#{Dir.pwd}/NotifiCLI.dmg"
  name "NotifiCLI"
  desc "Command-line tool for macOS notifications"
  homepage "https://github.com/saihgupr/NotifiCLI"

  app "NotifiCLI.app"
  binary "#{appdir}/NotifiCLI.app/Contents/MacOS/NotifiCLI", target: "notificli"

  zap trash: "~/Library/Application Support/NotifiCLI"
end
