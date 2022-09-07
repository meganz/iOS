
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
    agent { label 'mac-jenkins-slave-ios' }
    options {
        timeout(time: 1, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
        gitlabCommitStatus(name: 'Jenkins')
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
                                    dir("iMEGA/Vendor/Karere/src/") {
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
                                retry(3) {
                                    sh "sh download_3rdparty.sh"
                                }
                            })
                        }
                    }
                }
            }
        }

        stage('Build app') {
            steps {
                gitlabCommitStatus(name: 'Build app') {
                    injectEnvironments({
                        sh "bundle exec fastlane build_simulator"
                    })
                }
            }
        }

        stage('Upload app to Artifactory') {
            steps {
                gitlabCommitStatus(name: 'Upload app to Artifactory') {
                    injectEnvironments({
                        dir("${WORKSPACE}/derivedData/Build/Products/Debug-iphonesimulator"){ 
                            script {
                              def fileName = "${env.MEGA_VERSION_NUMBER}-${env.MEGA_BUILD_NUMBER}-simulator.zip"
                              sh "zip -r ${fileName} MEGA.app"
                              withCredentials([string(credentialsId: 'ios-mega-artifactory-upload', variable: 'ARTIFACTORY_TOKEN')]) {
                                env.zipPath = "${WORKSPACE}/derivedData/Build/Products/Debug-iphonesimulator/${fileName}"
                                env.targetPath = "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/${fileName}"
                                sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPath}\"'
                              }
                            }
                        }
                    })
                }
            }
        }    
    }
}
