pluginManagement {
    includeBuild("../..")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // 👇 هذا هو الصحيح — لا تضع version ولا apply:false
    id("dev.flutter.flutter-gradle-plugin")
    id("com.android.application") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")
