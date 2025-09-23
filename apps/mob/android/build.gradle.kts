// Repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// (Optional) relocate build outputs outside the module
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    // Each subproject builds under the relocated root build dir
    layout.buildDirectory.set(newBuildDir.dir(name))
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}