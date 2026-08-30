import com.android.build.api.variant.LibraryAndroidComponentsExtension

plugins {
    id("com.android.library") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// flutter_secure_storage 11 requests API 37 using the legacy integer form.
// Resolve the installed versioned SDK through AGP's public DSL, without changing
// the shared Pub cache or renaming SDK installations.
subprojects {
    if (name == "flutter_secure_storage") {
        plugins.withId("com.android.library") {
            extensions.getByType<LibraryAndroidComponentsExtension>().finalizeDsl { android ->
                android.compileSdk {
                    version = release(37) { minorApiLevel = 0 }
                }
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
