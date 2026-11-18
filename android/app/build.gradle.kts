import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release signing properties
val keystorePropertiesFile = rootProject.file("app/key.properties")
val keystoreProperties = Properties()

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
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "Missing android/app/key.properties"
                )
            }

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

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
