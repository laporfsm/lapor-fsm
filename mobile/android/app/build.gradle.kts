import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val requiredReleaseSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasCompleteReleaseSigning = keystorePropertiesFile.exists() &&
        requiredReleaseSigningKeys.all { key ->
            (keystoreProperties[key] as? String)?.isNotBlank() == true
        }
val isReleaseTaskRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true) ||
            taskName.contains("bundle", ignoreCase = true)
}
if (isReleaseTaskRequested && !hasCompleteReleaseSigning) {
    throw org.gradle.api.GradleException(
        "Release signing is required. Ensure android/key.properties contains storeFile, " +
                "storePassword, keyAlias, keyPassword, and the keystore file exists."
    )
}

android {
    namespace = "com.laporfsm.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.laporfsm.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasCompleteReleaseSigning) {
                val configuredStoreFile = rootProject.file(keystoreProperties["storeFile"] as String)
                if (!configuredStoreFile.exists()) {
                    throw org.gradle.api.GradleException("Keystore file not found: ${configuredStoreFile.path}")
                }
                storeFile = configuredStoreFile
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release")
        }
    }

    applicationVariants.all {
        val variantName = name
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
            val abi = output.filters.find { it.filterType == "ABI" }?.identifier
            if (abi != null) {
                output.outputFileName = "lapor-fsm-v${defaultConfig.versionName}-${abi}-${variantName}.apk"
            } else {
                output.outputFileName = "lapor-fsm-v${defaultConfig.versionName}-${variantName}.apk"
            }
        }
    }
}

afterEvaluate {
    tasks.named("assembleRelease").configure {
        doLast {
            val versionName = android.defaultConfig.versionName ?: "0.0.0"
            val from = file("$buildDir/outputs/flutter-apk/app-release.apk")
            val to = file("$buildDir/outputs/flutter-apk/lapor-fsm-v$versionName-release.apk")
            if (from.exists()) {
                from.copyTo(to, overwrite = true)
            }
        }
    }
    tasks.named("bundleRelease").configure {
        doLast {
            val versionName = android.defaultConfig.versionName ?: "0.0.0"
            val from = file("$buildDir/outputs/bundle/release/app-release.aab")
            val to = file("$buildDir/outputs/bundle/release/lapor-fsm-v$versionName-release.aab")
            if (from.exists()) {
                from.copyTo(to, overwrite = true)
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
}

flutter {
    source = "../.."
}

