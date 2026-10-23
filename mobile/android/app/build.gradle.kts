plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
        states.forEach { (uf, title) ->
            create(uf) {
                dimension = "state"
                applicationId = "com.onetour.$uf"
                resValue("string", "app_name", title)
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
