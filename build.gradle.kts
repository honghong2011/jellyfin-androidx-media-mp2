plugins {
    id("io.github.gradle-nexus.publish-plugin") version "1.1.0"
}

buildscript {
    repositories {
        mavenCentral()
        google()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.0.3")
    }
}

allprojects {
    group = "org.jellyfin.exoplayer"
    version = createVersion()

    repositories {
        mavenCentral()
        google()
    }
}

// 【修改】只在有发布凭证时才配置
nexusPublishing {
    repositories.sonatype {
        nexusUrl.set(uri("https://s01.oss.sonatype.org/service/local/"))
        snapshotRepositoryUrl.set(uri("https://s01.oss.sonatype.org/content/repositories/snapshots/"))

        // 加 try-catch 或默认值，避免报错
        username.set(project.findProperty("ossrh.username")?.toString() ?: "")
        password.set(project.findProperty("ossrh.password")?.toString() ?: "")
    }

    useStaging.set(project.provider { project.version.toString() != SNAPSHOT_VERSION })
}

tasks.wrapper {
    distributionType = Wrapper.DistributionType.ALL
}

tasks.create<Delete>("clean") {
    delete(rootProject.buildDir)
}
