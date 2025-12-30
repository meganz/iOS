
def injectEnvironments(Closure body) {
    withEnv([
        "PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

pipeline {
    agent { label 'mac-jenkins-slave-ios-xcode-26' }
    options {
        timeout(time: 1, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
        gitlabCommitStatus(name: 'Jenkins')
        ansiColor('xterm')
    }
    post { 
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Bundle install') {
            steps {
                gitlabCommitStatus(name: 'Bundle install') {
                    injectEnvironments({
                        sh "bundle install"
                    })
                }
            }
        }

        stage('Installing dependencies') {
            parallel {
                stage('Set build number and fetch version') {
                    steps {
                        gitlabCommitStatus(name: 'Set build number') {
                            injectEnvironments({
                                sh "bundle exec fastlane set_time_as_build_number"
                                sh "bundle exec fastlane fetch_version_number"
                                script {
                                    env.MEGA_BUILD_NUMBER = readFile(file: './fastlane/build_number.txt')
                                    env.MEGA_VERSION_NUMBER = readFile(file: './fastlane/version_number.txt')
                                }
                            })
                        }
                    }
                }

                stage('Submodule update and run cmake') {
                    steps {
                        gitlabCommitStatus(name: 'Submodule update and run cmake') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                injectEnvironments({
                                    sh "git submodule foreach --recursive git clean -xfd"
                                    sh "git submodule sync --recursive"
                                    sh "git submodule update --init --recursive"
                                    dir("Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK/src/") {
                                        sh "cmake -P genDbSchema.cmake"
                                    }
                                })
                            }
                        }
                    }
                }

                stage('Downloading third party libraries') {
                    steps {
                        gitlabCommitStatus(name: 'Downloading third party libraries') {
                            injectEnvironments({
                                sh "bundle exec fastlane configure_sdk_and_chat_library use_cache:true"
                            })
                        }
                    }
                }
            }
        }

        stage('Build app') {
            steps {
                gitlabCommitStatus(name: 'Build app') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            sh "bundle exec fastlane build_simulator"
                        })
                    }
                }
            }
        }

        stage('Upload app to Artifactory') {
            steps {
                gitlabCommitStatus(name: 'Upload app to Artifactory') {
                    injectEnvironments({
                        dir("${WORKSPACE}/derivedData/Build/Products/Debug-iphonesimulator"){ 
                            script {
                              def branchName = GIT_BRANCH.split('/').size() > 1 ? GIT_BRANCH.split('/')[1..-1].join('-') : GIT_BRANCH.replace('/', '-')
                              echo 'Pulling from branch :' + branchName

                              def fileName = "${env.MEGA_VERSION_NUMBER}-${env.MEGA_BUILD_NUMBER}-${branchName}-simulator.zip"
                              sh "zip -r ${fileName} MEGA.app"

                              withCredentials([string(credentialsId: 'ios-mega-artifactory-upload', variable: 'ARTIFACTORY_TOKEN')]) {
                                env.zipPath = "${WORKSPACE}/derivedData/Build/Products/Debug-iphonesimulator/${fileName}"
                                env.targetPath = "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/simulator"
                                env.latest = "ios-mega-simulator-latest.zip"

                                // Path : latest                                
                                env.targetPathLatest = "${env.targetPath}/latest/${env.latest}"

                                // Path : dailybuilds
                                env.targetPathDailybuilds = "${env.targetPath}/dailybuilds/${fileName}"
                                env.targetPathDailybuildsLatest = "${env.targetPath}/dailybuilds/${env.latest}"

                                // Path : dailybuilds
                                env.targetPathRelease = "${env.targetPath}/release/${fileName}"
                                env.targetPathReleaseLatest = "${env.targetPath}/release/${env.latest}"
                                echo 'Branch name =' + branchName

                                if (branchName == 'develop') {
                                    // dailybuilds
                                    echo 'Pulling dailybuilds from :' + branchName
                                    sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPathLatest}\"'
                                    sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPathDailybuildsLatest}\"'
                                    sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPathDailybuilds}\"'
                                }
                                else{
                                    // release build
                                    echo 'Pulling release build from :' + branchName
                                    sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPathLatest}\"'
                                    sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPathReleaseLatest}\"'
                                    sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPathRelease}\"'
                                }
                              }
                            }
                        }
                    })
                }
            }
        }    
    }
}
