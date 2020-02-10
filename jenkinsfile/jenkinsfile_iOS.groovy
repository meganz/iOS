def clearnProject() {
        sh "git clean -f"

}

def injectEnvironments(Closure body) {
    withEnv([
        "PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH",
        "PATH=$PATH:/usr/local/bin",
        "PATH=/Applications/CMake.app/Contents/bin:$PATH",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

stage('clone repro') {
    node {
        clearnProject()
        checkout scm
        injectEnvironments({
            sh "git submodule update --init --recursive"
        })
    }
}

stage('download depedency') {
    node {
        injectEnvironments({
            sh "git submodule update --init --recursive"
            sh "export PATH=/Applications/MEGAcmd.app/Contents/MacOS:$PATH"
            sh "mega-get https://mega.nz/#!CjwkmYTB!gIJrmV5cR3Nk4ZTYTY-89aVYEioD-RU_vAOMPZsfcdA $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/"
        })
    }
}

stage('unzip depedency') {
    node {
        injectEnvironments({
            sh "unzip -o $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/wrtc.zip -d $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/"
        })
    }
}

stage('Initial Build') {
    node {
        injectEnvironments({
            dir("iMEGA/Vendor/Karere/src/") {
                sh "cmake -P genDbSchema.cmake"
            }
        })
    }
}

stage('build ipa') {
    node {
        injectEnvironments({
            sh "fastlane build BUILD_NUMBER:$BUILD_NUMBER appcenter_api_token:$appcenter_api_token"
        })
    }
}

stage('deploy to appcenter') {
    node {
        injectEnvironments({
            retry(3) {
                sh "fastlane upload ENV:DEV"
            }
        })
    }
}