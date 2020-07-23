# Trash Master
This app was created as a Capstone project for Ada Developer Academy. The purpose of the app is to reduce trash in the environment. 

![Welcome](/Images/Welcome.png?raw=true =250x400)
![Navigator](/Images/Navigator.png?raw=true =250x400)

## Feature Set
The mission of the app is carried out in two ways: 

### Navigator
Provides a map marked with locations of the nearest trash cans and bathrooms, along with a navigation route to them. All users can help contribute to the map by adding in markers for trash cans and bathrooms. 

### Trash Report
Provides a map to be marked with reports of trash in the area (i.e. excessive litter, abandoned furniture). Any user can help contribute to the map by making reports of where they notice trash. Reports include the location, description, and image of the trash. Once a report is saved, any user can see the annotation on the map and click on it for more information. 

## Dependencies
Trash Master relies on:

- Google Firebase
  - Firebase/Core
  - Firebase/Database
  - Firebase/Storage
- Apple Mapkit

## Environment Set-up

### Xcode Installation
Xcode is a complete developer toolset for creating apps for Mac, iPhone, iPad, Apple Watch, and Apple TV. Changes to the app must be done in Xcode. The current release of Xcode is available as a free download from the Mac App Store. 

### CocoaPods
CocoaPods manages library dependencies for your Xcode projects. The dependencies for projects are specified in a single text file called a Podfile. CocoaPods will resolve dependencies between libraries, fetch the resulting source code, then link it together in an Xcode workspace to build your project.

CocoaPods can be installed by running the following command in the terminal: 
```
$ sudo gem install cocoapods
```

After CocoaPods is installed, run the following command in the terminal to get access to the appropriate Pods:
```
$ pod install
```

Pod files can be extremely large so it is recommended to avoid pushing them to Github. Go to the project folder and run the following commands to create and add Pods to your .gitignore file:
```
$ touch .gitignore
$ echo "Pods/" > .gitignore
```

Once the Firebase pods have been installed, the app will be able to initialize appropriate modules needed to run the code. 

### Google Firebase
This project is currently a registered with Firebase as an iOS app so no further action needs to be taken to create a database. See the Google Firebase documentation for more information on how the app was registered. 

In order to connect to Firebase, the file GoogleService-Info.plist (firebase iOS config file) needs to be saved to the root of the project. 




