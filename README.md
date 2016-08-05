# TwilioQwikEyes

Before you start, make sure your Xcode is updated to support:
Xcode 7.2.1

Swift 2.1

iOS 8.1 and up

Once that is done, create a Twilio account from twilio.com

Follow the quickstart guide to create the 4 required API Keys.

Twilio Quickstart Guide - https://www.twilio.com/docs/api/video/guide/quickstart-ios

I have installed all the dependencies for the app permanently. If for some reason the app doesn't build, you can add the dependencies using the following instructions:

- Open up the Podfile in the Pods folder and paste these lines:

source 'https://github.com/twilio/cocoapod-specs'
source 'https://github.com/CocoaPods/Specs.git'
target 'VideoQuickStart' do
    pod 'TwilioConversationsClient', '~>0.25.0'
    use_frameworks!
    pod 'SnapKit', '~> 0.15.0'
    pod 'SwiftyTimer'
end

- Save it, and from the terminal, navigate to the file's location and execute the command 'pod install'. This will take a while, but will install everything required.

Once the app is built, create a test token here: https://www.twilio.com/user/account/video/dev-tools/testing-tools

Copy the generated token into your app in ViewController.swift, for the variable "accessToken".

Run the app. Once it is running, on the page where you created the test token, navigate to the part of the page with the button "Create conversation". This should start streaming from both your phone and Mac.
