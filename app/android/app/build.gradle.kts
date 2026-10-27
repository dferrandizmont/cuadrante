import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (docs/release-signing.md). The upload key lives outside the
// repository; android/key.properties (gitignored) points at it.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) keyPropertiesFile.inputStream().use { load(it) }
}
val hasReleaseKey = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !keyProperties.getProperty(it).isNullOrBlank() }

// `-PallowDebugSigning=true` signs the release with this machine's Android
// debug key, even when key.properties exists: ONLY for local tests and the
// test APKs of tool/release_android.sh (so they keep updating the installed
// test app), never for Google Play.
// Read from the command line only: a stale entry in a gradle.properties file
// must never debug-sign a Play build.
val allowDebugSigning =
    gradle.startParameter.projectProperties["allowDebugSigning"]?.toBoolean() == true

val releaseProblems: List<String> = buildList {
    if (allowDebugSigning && gradle.startParameter.taskNames.any { it.startsWith("bundle") }) {
        add("-PallowDebugSigning=true is for test APKs only; an app bundle (.aab) goes to Google Play.")
    }
    if (allowDebugSigning) return@buildList
    if (keyPropertiesFile.exists() && !hasReleaseKey) {
        add("android/key.properties must define storeFile, storePassword, keyAlias and keyPassword.")
    } else if (!hasReleaseKey) {
        add(
            "android/key.properties is missing, so there is no upload key. " +
                "Local test builds only: add -PallowDebugSigning=true.",
        )
    }
}

fun releaseFailure(): GradleException = GradleException(
    "\n==============================================================\n" +
        " Refusing to build a RELEASE:\n" +
        releaseProblems.joinToString("\n") { " - $it" } +
        "\n See docs/release-signing.md for the exact commands.\n" +
        "==============================================================",
)

// Fail before anything is compiled when a release task was requested...
if (releaseProblems.isNotEmpty() &&
    gradle.startParameter.taskNames.any { it.contains("Release") }
) {
    throw releaseFailure()
}

android {
    namespace = "es.cuadrante.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time on Android < 26.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "es.cuadrante.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (allowDebugSigning) {
                logger.warn(
                    "\n==============================================================\n" +
                        " -PallowDebugSigning=true: the RELEASE build is signed\n" +
                        " with the DEBUG key. Local test builds only.\n" +
                        "==============================================================",
                )
                signingConfigs.getByName("debug")
            } else if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                null // the release guard fails the build
            }
        }
    }
}

// ...and as a backstop when a release variant is built through another entry
// point (an IDE, a task name without "Release").
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    val failure = if (releaseProblems.isEmpty()) null else releaseFailure().message
    doFirst {
        if (failure != null) throw GradleException(failure)
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Home-screen widgets: the 6-hourly safety refresh (docs/widget-contrato.md).
    // Same version as the one home_widget already brings in.
    implementation("androidx.work:work-runtime-ktx:2.11.2")

    // JVM tests of pure logic (widget day logic, file reading, launch policy):
    // `./gradlew :app:testDebugUnitTest`.
    // org.json is stubbed in the Android jar, so the tests bring the real one.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}
