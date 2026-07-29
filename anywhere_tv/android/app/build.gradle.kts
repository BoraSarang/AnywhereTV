import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun propOrEnv(key: String, env: String): String? =
    (keystoreProperties[key] as? String)?.takeIf { it.isNotEmpty() }
        ?: System.getenv(env)?.takeIf { it.isNotEmpty() }

android {
    namespace = "com.borasarang.anywheretv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.borasarang.anywheretv"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val storeFileEnv = propOrEnv("storeFile", "ANDROID_STORE_FILE")
    val hasSigning = storeFileEnv != null
            && propOrEnv("keyAlias", "ANDROID_KEY_ALIAS") != null
            && propOrEnv("keyPassword", "ANDROID_KEY_PASSWORD") != null
            && propOrEnv("storePassword", "ANDROID_STORE_PASSWORD") != null

    if (hasSigning) {
        signingConfigs {
            create("release") {
                keyAlias = propOrEnv("keyAlias", "ANDROID_KEY_ALIAS")!!
                keyPassword = propOrEnv("keyPassword", "ANDROID_KEY_PASSWORD")!!
                storeFile = rootProject.file(storeFileEnv!!)
                storePassword = propOrEnv("storePassword", "ANDROID_STORE_PASSWORD")!!
            }
        }
    }

    buildTypes {
        release {
            if (hasSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
