import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release signing properties
val keystorePropertiesFile = rootProject.file("app/key.properties")
val keystoreProperties = Properties()
val testBuild = providers.gradleProperty("bioTestBuild").orNull == "true" || System.getenv("BIOJAVER_TEST_BUILD") == "true"

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}

android {
    namespace = "com.biojaveriana.client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId = "com.biojaveriana.client"
        if (testBuild) applicationIdSuffix = ".preview"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
          if (keystorePropertiesFile.exists()) {

            storeFile = file(
                keystoreProperties.getProperty("storeFile")
                    ?: throw GradleException("Missing storeFile")
            )

            storePassword = keystoreProperties.getProperty("storePassword")
                ?: throw GradleException("Missing storePassword")

            keyAlias = keystoreProperties.getProperty("keyAlias")
                ?: throw GradleException("Missing keyAlias")

            keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: throw GradleException("Missing keyPassword")
          }
        }
    }

    buildTypes {
        release {
            if (!testBuild && !keystorePropertiesFile.exists() &&
                gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }) {
                throw GradleException("Missing android/app/key.properties for production signing")
            }
            signingConfig = signingConfigs.getByName(if (testBuild) "debug" else "release")
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
