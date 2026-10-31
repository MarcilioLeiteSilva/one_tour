import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.onetour.one_tour_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.onetour.one_tour_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "One Tour")
        manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            storeFile = if (storeFilePath != null) rootProject.file(storeFilePath) else null
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    flavorDimensions += "state"
    productFlavors {
        val states = mapOf(
            "pe" to "Tour Pernambuco",
            "sp" to "Tour São Paulo",
            "rj" to "Tour Rio de Janeiro",
            "ba" to "Tour Bahia",
            "mg" to "Tour Minas Gerais",
            "ce" to "Tour Ceará",
            "pr" to "Tour Paraná",
            "sc" to "Tour Santa Catarina",
            "rs" to "Tour Rio Grande do Sul",
            "al" to "Tour Alagoas",
            "pb" to "Tour Paraíba",
            "rn" to "Tour Rio Grande do Norte",
            "se" to "Tour Sergipe",
            "ma" to "Tour Maranhão",
            "pi" to "Tour Piauí",
            "es" to "Tour Espírito Santo",
            "go" to "Tour Goiás",
            "df" to "Tour Distrito Federal",
            "mt" to "Tour Mato Grosso",
            "ms" to "Tour Mato Grosso do Sul",
            "am" to "Tour Amazonas",
            "pa" to "Tour Pará",
            "to" to "Tour Tocantins",
            "ro" to "Tour Rondônia",
            "ac" to "Tour Acre",
            "ap" to "Tour Amapá",
            "rr" to "Tour Roraima"
        )
        val admobAppIds = mapOf(
            "pe" to "ca-app-pub-5133242303791049~4445477549",
            "al" to "ca-app-pub-5133242303791049~3525828291"
        )
        val defaultAdmobAppId = "ca-app-pub-3940256099942544~3347511713" // Google sample test App ID

        states.forEach { (uf, title) ->
            create(uf) {
                dimension = "state"
                applicationId = "com.onetour.$uf"
                resValue("string", "app_name", title)
                manifestPlaceholders["admobAppId"] = admobAppIds[uf] ?: defaultAdmobAppId
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists() && keystoreProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
