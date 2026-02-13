allprojects {
    repositories {
        google()
        mavenCentral()
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

    project.evaluationDependsOn(":app")

    // Fix for plugins that don't declare a namespace (e.g. better_player)
    project.plugins.withId("com.android.library") {
        val extension = project.extensions.getByType<com.android.build.gradle.LibraryExtension>()
        if (extension.namespace == null) {
            extension.namespace = project.group.toString().ifEmpty {
                "com.jhomlala.${project.name.replace("-", "_")}"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
