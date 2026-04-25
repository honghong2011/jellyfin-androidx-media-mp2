name: ExoPlayer FFmpeg Extension Publish

on:
  push:
    tags:
      - v*
    branches:
      - master

jobs:
  build:
    runs-on: ubuntu-22.04
    environment: release
    if: ${{ !startsWith(github.ref, 'refs/pull/') }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 11

      # 【修复】安装 NDK 21 + CMake 3.10.2，并设置完整环境变量
      - name: Setup Android SDK
        run: |
          export ANDROID_SDK_ROOT=$HOME/android-sdk
          mkdir -p $ANDROID_SDK_ROOT/cmdline-tools
          cd $ANDROID_SDK_ROOT/cmdline-tools
          wget -q https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
          unzip -q commandlinetools-linux-8512546_latest.zip
          mv cmdline-tools latest
          export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH
          yes | sdkmanager --licenses >/dev/null 2>&1 || true
          sdkmanager "ndk;21.4.7075529" "cmake;3.10.2.4988404"
          echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> $GITHUB_ENV
          echo "ANDROID_HOME=$ANDROID_SDK_ROOT" >> $GITHUB_ENV
          echo "ANDROID_NDK_HOME=$ANDROID_SDK_ROOT/ndk/21.4.7075529" >> $GITHUB_ENV

      - name: Build ffmpeg
        run: ./build.sh

      - name: Force specific version of cmake
        run: |
          cmake=(${ANDROID_SDK_ROOT}/cmake/3.10.2*)
          echo cmake.dir="${cmake[0]}" | tee -a local.properties

      - name: Set JELLYFIN_VERSION
        if: ${{ startsWith(github.ref, 'refs/tags/v') }}
        run: echo "JELLYFIN_VERSION=$(echo ${GITHUB_REF#refs/tags/v} | tr / -)" >> $GITHUB_ENV

      # 【改回原版模块名】
      - name: Build extension only (no publish)
        run: ./gradlew :exoplayer-ffmpeg-extension:assembleRelease

      - name: Upload compiled AAR package
        uses: actions/upload-artifact@v4
        with:
          name: exoplayer-ffmpeg-extension-aar
          path: exoplayer-ffmpeg-extension/build/outputs/aar/*.aar
