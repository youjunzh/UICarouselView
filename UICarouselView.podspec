Pod::Spec.new do |s|
    s.name             = 'UICarouselView'
    s.version          = '0.1.0'
    s.summary          = 'CarouselView written in swift'

    s.description      = <<-DESC
    Rewrite iCasourel (https://github.com/nicklockwood/iCarousel) using swift 4.1
    DESC

    s.homepage         = 'https://github.com/youjunzh/UICarouselView'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'youjunzh' => 'youjunzh@users.noreply.github.com' }
    s.source           = { :git => 'https://github.com/youjunzh/UICarouselView.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

    s.ios.deployment_target = '11.0'

    s.default_subspec = "Core"

    s.subspec "Core" do |ss|
        ss.source_files  = "Sources/Classes/UICarouselView/*"
        ss.framework  = "Foundation","QuartzCore"
    end

    s.subspec "Banner" do |ss|
        ss.source_files = "Sources/Classes/Banner/*"
        ss.dependency "UICarouselView/Core"
        ss.dependency "Kingfisher", "~> 4.9.0"
    end


    # s.resource_bundles = {
    #   'UICarouselView' => ['UICarouselView/Assets/*.png']
    # }

    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    # s.dependency 'AFNetworking', '~> 2.3'
end
