Pod::Spec.new do |s|

  s.name         = "ATGMediaBrowser"
  s.version      = "1.2.0"
  s.summary      = "Image slide show viewer with multiple predefined transition styles, and with ability to create new transitions with ease."

  s.swift_version= "5.0"

  s.description  = <<-DESC
ATGMediaBrowser is an image slide show viewer that supports multiple predefined transition styles, and also allows the client to define new transition styles. It supports both horizontal and vertical gestures to control transitions, and adding new transitions is fun and easy.
                   DESC

  s.homepage     = "https://github.com/altayer-digital/ATGMediaBrowser"
  s.screenshots  = "https://i.imgur.com/NfKfnoC.gif", "https://i.imgur.com/EmR7uU5.gif", "https://i.imgur.com/v8wsKiF.gif", "https://i.imgur.com/bx2a2iv.gif"

  s.license      = { :type => "MIT", :file => "LICENSE.md" }

  s.author       = { "surajthomask" => "suthomas@altayer.com" }

  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/altayer-digital/ATGMediaBrowser.git", :tag => "#{s.version}" }

  s.source_files  = "ATGMediaBrowser", "ATGMediaBrowser/**/*.swift"
  s.exclude_files = "ATGMediaBrowser/Info.plist"

end
