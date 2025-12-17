pluginManagement {
    val flutterSdkPath = try {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    } catch (e: Exception) {
        throw GradleException("flutter.sdk not found in local.properties")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // [버전 상향] 경고 메시지 해결을 위해 8.6.0 사용
    id("com.android.application") version "8.6.0" apply false
    // [버전 상향] 호환성이 좋은 최신 버전
    id("org.jetbrains.kotlin.android") version "2.1.10" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")