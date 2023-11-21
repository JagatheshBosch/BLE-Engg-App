# sOPEP App

This is a Flutter based app used to test the features and functionalities of the sOPEP device using BLE. This Flutter app uses the [`flutter_reactive_ble`](https://github.com/PhilipsHue/flutter_reactive_ble) plugin for all BLE connection/communication and this app is based on the example provided by the [Flutter Reactive BLE](https://github.com/PhilipsHue/flutter_reactive_ble) authors.

## Setup for Development

Below provides instructions on setting up Flutter and other various framework/tools for development.

### Setup Flutter SDK

Follow the instructions provided [here](https://docs.flutter.dev/get-started/install) to install Flutter using VS Code on any OS. Note that you CANNOT COMPILE/RUN ON iOS unless you have macOS. After following the Flutter install instructions, you will have completed the following,

1. Installed VS Code with Flutter SDK (useful VS Code extensions include Flutter, Dart, and Gradle for Java extensions).
2. Installed Android Studio with Google Play Account.
3. Installed Xcode with Apple Developer Account (macOS only).

Ensure you have flutter/bin in your global PATH (e.g., instructions for [macOS](https://docs.flutter.dev/get-started/install/macos#update-your-path) and adding it [permanently to macOS PATH](https://techpp.com/2021/09/08/set-path-variable-in-macos-guide/)) for easy access to the Flutter SDK binaries. This will allow you to run Flutter commands from the VS Code terminal easily and save you a lot of typing time.

To check if everything for Flutter was installed corrected, open up a terminal (or cmd.exe for Windows) and run the following command (this assumes you have added flutter/bin directory to the global PATH),

```flutter doctor```

If everything was installed correctly, you will see all checkmarks as shown in the below figure (Xcode will not be visble unless you are working on macOS).

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/5736a026-a0ea-4e93-bb05-65bb68862f4e)

### Setup Phones

You will need to setup your Android and iPhone devices to be in developer mode (or, alternatively, you can use the  emulators provided by Flutter for these OS). Follow the instructions provided in the below links to enable developer mode.

| OS | Links |
|---|---|
| Android | https://www.samsung.com/uk/support/mobile-devices/how-do-i-turn-on-the-developer-options-menu-on-my-samsung-galaxy-device/|
| iOS | https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device |

### Setup Repo

First, pull (or download) from the latest main branch to your local directory. Next, open up VS Code and open the folder directory of the newly downloaded project files and VS Code will initialize the Flutter project. Once opened, open a new terminal on VS Code and type the following command (note that this assumes you have added flutter/bin to your global PATH),

```flutter clean```

The above command removes any build files that were generated from compiling and cleans the entire Flutter project. Once the clean command is completed, connect a device that you will use for development to the computer (or, choose an emulator), unlock the device, and VS Code (at the bottom right of the IDE) will indicate a development device is connected as shown in the below figure (e.g., Justin's iPhone (iOS)).

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/803bc4d7-b33c-4f8d-a77c-e10d67683c33)

After the development device has been successfully detected/connected to the computer, you can run the following command to compile and run the app on the test device,

```flutter run```

If everything was successful, you will see the test app running on your connected device!

### Setup Firebase (Optional)

Firebase is used to handle all backend related tasks (e.g., login authentication, cloud data storage, etc.) and is used with this Flutter app. Note that this is optional and is not needed if you only want to install and run the Flutter app on the target devices and do not plan on doing any Firebase related development. Follow the instructions below to complete the Firebase setup.

First, follow the instructions from [here](https://firebase.google.com/docs/cli) to install the Firebase CLI. On any OS, you can run the following command in terminal to auto-setup everything,

```sudo curl -sL https://firebase.tools | bash```

Next, you will need to activate Flutter Fire CLI with the following command in terminal,

```dart pub global activate flutterfire_cli```

Note that it may ask you to include the `.pub-cache/bin` to the global PATH and provide instructions on how to complete that (e.g., add `export PATH="$PATH":"$HOME/.pub-cache/bin"` to `~/.zshrc` file for macOS).

With the above instructions completed, you now need to log into Firebase. If you have not yet created a Google account and registered it with Firebase, do so [here](https://firebase.google.com/). On your terminal, type the following command and it will direct you to Firebase login website on your browser (make sure to use the StarIC Google account which has the correct Firebase project setup),

```firebase login```

Once you have successfully logged in from the browser and allow permissions necessary to access Firebase, you can re-run the above command again in terminal and it should give you a message, `Already logged in as youremailhere@gmail.com`.

Now, open up the VS Code with the Flutter project that you would like to setup Firebase with. Open up a VS Code terminal (make sure it is at your Flutter project's root folder) and run the following command (note that below command may be different for your and should be grabbed from your Firebase project setup page!),

```flutterfire configure --project=sopep-6b4ad```

To ensure you have the correct Firebase project ID above, you can go to your Firebase console and go into the project console and choose to setup a Flutter app to see the below interface with the terminal command which includes the ID.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/d98a32c1-7c52-4372-bae7-aaaef14e4627)

After, the terminal will ask you to choose a Firebase project (or not, if you only have one project), and ask you which platforms you would like to support (i.e., iOS, Android, macOS, and/or web) as shown in the below figure.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/a335b728-6657-49e8-8f5f-4d5156ea89ce)

For this Flutter project, only Android and iOS will be supported so leave it the way it is as shown in the above figure.

Once the above configuration is completed successfully, you will see the following output from the VS Code terminal.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/cd19b5fe-0b6c-42be-9572-978abce3c134)

And on your Firebase console, you will see the following for Android apps and Apple apps.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/1565a1eb-09ae-4709-a439-4280d4dafe01)

There may be a case where the Firebase Core was not installed on your Flutter project which can be resolved by running the following command in your VS Code project terminal,

```flutter pub add firebase_core```

## BLE Data Transmission

All BLE communication between the app and the sOPEP device uses an encoder/decoder for TX/RX on each side. The encoder is based on UnitCircle's IP using concise binary object representation (CBOR), cyclic redundancy check (CRC32C), and COBS for structuring (serializating), checking, and breaking up (framing) the datasets, respectively (and decoder is reversed in order of operation). Below figure provides a high-level overview of how the BLE communications are done.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/fd32a955-e534-43ae-8ecd-3b36401493bb)

### Message Structure

The BLE message is structured using a map format (e.g., Map<Object, Object>) and an example is provided below for sending a read command,

```
cmd = {
    'cmd': 'read-data',
    'seq': 4096
}
```

Note how in the above example, the first object in the map are all `String` variables and the right column of variables are a mix of `String` and `Int` (other variable types can include `Float16` and `Float32`).

### Useful Links for Prototyping

Below table provides links to the various tools for encoding/checksum methods used for encoding/decoding the BLE datasets.

| Description | Links |
| ----------- | ----------- |
| Decimal array to hex array | https://www.duplichecker.com/decimal-to-hex.php |
| CBOR | https://cbor.me/ |
| CRC32C | https://crccalc.com/ |
| COBS | https://crccalc.com/bytestuffing.php |

## Listing All Used SOUP

Flutter makes it easy to see the list of all used software of unknown provenance  (i.e., software of unknown provenance; SOUP). To view the SOUP list, open up the project on VS Code and open a new terminal. On the terminal type of the following command,

```flutter pub deps```

After, you will see the following long lines of output on the terminal (below only shows the initial portion),

```
Dart SDK 3.0.5
Flutter SDK 3.10.5
sopep_app 0.1.0+1
├── build_runner 2.4.5
│   ├── analyzer 5.13.0
│   │   ├── _fe_analyzer_shared 61.0.0
│   │   │   └── meta...
│   │   ├── collection...
│   │   ├── convert...
│   │   ├── crypto...
│   │   ├── glob...
│   │   ├── meta...
│   │   ├── package_config...
│   │   ├── path...
│   │   ├── pub_semver...
│   │   ├── source_span...
│   │   ├── watcher...
│   │   └── yaml...
│   ├── args 2.4.2
│   ├── async 2.11.0
│   │   ├── collection...
│   │   └── meta...
│   ├── build 2.4.0
│   │   ├── analyzer...
...
```

Alternatively, you can view the pubspec.yaml file in the project root folder (i.e., sopep_app/pubspec.yaml) which will list all the dependecies used in the Flutter project, as shown below.

```
name: sopep_app
description: Mobile app used to test the sOPEP device.
version: 0.1.0+1
publish_to: 'none'

environment:
  sdk: '>=2.12.0 <3.0.0'
  flutter: ">=1.10.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_lints: ^1.0.4
  flutter_reactive_ble: ^5.1.1
  functional_data: ^1.0.0
  intl: ^0.17.0
  cbor: ^5.1.2
  crclib: ^3.0.0
  cobs2: ^0.2.0
  wakelock: ^0.6.2
  provider: ^6.0.1
  package_info_plus: ^3.0.3
  flutter_spinkit: ^5.2.0

dev_dependencies:
  build_runner: ^2.3.3
  dependency_validator: ^3.1.0
  flutter_test:
    sdk: flutter
  functional_data_generator: ^1.1.2
  change_app_package_name: ^1.1.0

flutter:
  uses-material-design: true
```

## Setup Flutter CI + Firebase (Optional)

GitHub Actions is used for this Flutter project continuous integration (CI) where it will build the iOS and Android apps using [subosito/flutter-action](https://github.com/subosito/flutter-action) and deploy these apps to Firebase App Distribution using [wzieba/Firebase-Distribution-Github-Action](https://github.com/wzieba/Firebase-Distribution-Github-Action) for providing the apps to selected testers.

### Setup CI GitHub Actions

The CI script can be found in .github/workflows/ci.yml where it needs the following secret variables to work,

1. SOPEP_FIREBASE_IOS_APPID.
2. SOPEP_FIREBASE_ANDROID_APPID
3. SOPEP_CREDENTIAL_FILE_CONTENT

The iOS and Android app IDs can be found by first going to your Firebase project's overview page and selecting the settings button for either Android or iOS (iOS example shown in the below figure).

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/bcc1d705-e49a-4f6f-9392-ce6db12ec188)

In the settings page for iOS (or Android), scroll down to see the app ID value which will be needed for the CI script.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/b43e422d-121d-49df-b5b7-d05eb95aa8ca)

Add the iOS and Android app ID to the GitHub project secret variables by going to `Settings` -> `Secrets and variables` -> `Actions` -> `New repository secret`. Name the iOS app ID secret `SOPEP_FIREBASE_IOS_APPID` and copy and paste the app ID from the Firebase console. Do the same for Android but with the secret name `SOPEP_FIREBASE_ANDROID_APPID`. After everything has been entered, the secret variables should look like the below figure.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/1d25a700-a03b-4fa0-b59d-bbb0b45fc695)

To get the `SOPEP_CREDENTIAL_FILE_CONTENT`, we need to create a service account on Google Cloud Console for the sOPEP project. First, go to [Google Cloud Console](https://console.cloud.google.com/projectselector2/iam-admin/serviceaccounts). Next, select the project on the top scroll list (e.g., sOPEP) and go to Service Accounts on the left menu as shown in the below figure.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/90c57caf-6193-4c1d-8c89-698fbdb270df)

You can follow the rest of the setup instructions from [here](https://github.com/wzieba/Firebase-Distribution-Github-Action/wiki/FIREBASE_TOKEN-migration).

By the end of the instructions, you will have a JSON file with the required key for `SOPEP_CREDENTIAL_FILE_CONTENT`, where you will create a new repo secret variable called `SOPEP_CREDENTIAL_FILE_CONTENT` and copy and paste the JSON file content as the value for this secret variable.

Next, try creating a branch, commit new changes to the new branch, initiate a pull request, and see the CI GitHub Actions go to work!

### Setup for Android Release Builds

Follow the steps [here](https://docs.flutter.dev/deployment/android#create-an-upload-keystore) to generate a key file and key.properties for Android release build. Note that for key.properties, the `storeFile` location is set to the root folder of the project's Android folder (i.e., sopep_app/android/upload-keystore.jks) and the `storeFile` location is set to the following.

```storeFile=../upload-keystore.jks```

DO NOT SHARE THIS FILE TO ANYONE AND SHOULD BE KEPT PRIVATE! The only reason why this file is in the repo is because the repo will always stay private. For new projects, you would need to create a new upload-keystore.jks file with a new password.

Next, we need to link our Google Playstore Account to Firebase but this requires us to upload the properly signed release build .aab app file to the Google Playstore. You can upload this .aab file without publishing to the Google Play Store. This is done so that same signed Android app can be found in the Google Play Store database which is needed for Firebase to properly link our test app to the Google Play Store account. To generate the .aab app file (this is a one time thing just for Google Play Console), run the following commands on VS Code terminal, and it will be located in sopep/build/app/outputs/appbundle/app-release.aab.

```
flutter clean
flutter build apk --release --no-tree-shake-icons
```

Once you have uploaded the signed release build .aab file to the Google Play Store, you will see something like in the below figure.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/86bc80e0-e537-4049-8aba-bc382b8547c0)

Once the Android app is uploaded, you will need to complete several steps to get the app towards published (internal) phase by completing various questionaire and verify your personal identity (e.g., using driver's license).

After the above is completed, go back to `Firebase -> Project Settings -> Integration` and click `Link` under Google Play Store as shown in the below figure.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/35b5d081-0047-4e92-a960-b4f8ef1895d6)

Make sure you enable all toggle buttons as shown in the below figure.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/16aa74a3-f22d-4556-9dda-670e3a4aadd4)

Once linked successfully, you will see the following in your Integration tab page.

![image](https://github.com/StarIC-ca/sopep_app_test/assets/79532677/d2ec5795-7e56-4ed1-906f-93cb7118a18d)

After the above step and running the CI with Android related jobs, the CI will automatically build the Android .apk app file (note that we uploaded .aab and not .apk for the Google Play Console) and push to Firebase for Firebase App Distribution.

