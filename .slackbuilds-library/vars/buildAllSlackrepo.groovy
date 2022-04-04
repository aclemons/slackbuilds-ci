def call() {
    def userId = sh(returnStdout: true, script: '#!/bin/sh -e\nid -u jenkins').trim()
    def groupId = sh(returnStdout: true, script: '#!/bin/sh -e\nid -g jenkins').trim()

    dir ('log') {
        sh '#!/bin/sh -e\necho "Created log directory: $(pwd)"'
    }

    def packageName = env.PACKAGE_NAME

    def buildArch = env.BUILD_ARCH
    if (buildArch == null) {
        buildArch = ''
    }

    def optRepo = env.OPT_REPO

    if (optRepo == null) {
        optRepo = 'SBo'
    }

    def setArch = env.SETARCH

    if (setArch == null) {
        setArch = ''
    }

    def projects = null
    if ("true".equals(env.ENABLE_PACKAGE_LISTING)) {
        // experimental project listing - currently very slow since we have to stop and start a container for each package to build
        docker.image(env.SLACKREPO_DOCKER_IMAGE).inside("-u 0 --cap-add SYS_ADMIN -v ${env.SLACKREPO_DIR}:/var/lib/slackrepo/${optRepo}") {
            ansiColor('xterm') {
                withEnv(["PACKAGE=${packageName}", "JENKINSUID=${userId}", "JENKINSGUID=${groupId}", "BUILD_ARCH=${buildArch}", "OPT_REPO=${optRepo}", "SETARCH=${setArch}"]) {
                    sh(returnStatus: true, script: libraryResource('build_package_list_with_slackrepo.sh'))
                }
            }
        }

        projects = sh(returnStdout: true, script: "sort -r tmp/project_list").split()
    } else {
        projects = packageName?.split(" ")
    }

    // re-init log/tmp
    sh 'rm -rf log tmp'
    dir ('log') {
        sh '#!/bin/sh -e\necho "Created log directory: $(pwd)"'
    }

    echo "Found ${projects?.size()} projects to build"

    try {
        if (projects == null) {
            docker.image(env.SLACKREPO_DOCKER_IMAGE).inside("-u 0 --cap-add SYS_ADMIN -v ${env.SLACKREPO_DIR}:/var/lib/slackrepo/${optRepo}") {
                if ("true".equals(env.SEED_UID_GID)) {
                    createAllUsersAndGroups()
                }

                ansiColor('xterm') {
                    withEnv(["JENKINSUID=${userId}", "JENKINSGUID=${groupId}", "BUILD_ARCH=${buildArch}", "OPT_REPO=${optRepo}", "SETARCH=${setArch}"]) {
                        sh(returnStatus: true, script: libraryResource('build_with_slackrepo.sh'))

                        writeFile(file: 'slackrepo_parse.rb', text: libraryResource('slackrepo_parse.rb'))

                        sh "LANG=en_US.UTF-8 ruby slackrepo_parse.rb '$JOB_NAME' 'tmp/checkstyle.xml' 'tmp/junit.xml' 'tmp/build'"
                    }
                }

            }

            junit allowEmptyResults: true, testResults: "tmp/junit.xml"
        } else {
            projects.each {
                echo "Building ${it}"

                docker.image(env.SLACKREPO_DOCKER_IMAGE).inside("-u 0 --cap-add SYS_ADMIN -v ${env.SLACKREPO_DIR}:/var/lib/slackrepo/${optRepo}") {
                    if ("true".equals(env.SEED_UID_GID)) {
                        createAllUsersAndGroups()
                    }

                    ansiColor('xterm') {
                        withEnv(["PROJECT=${it}", "JENKINSUID=${userId}", "JENKINSGUID=${groupId}", "BUILD_ARCH=${buildArch}", "OPT_REPO=${optRepo}", "SETARCH=${setArch}"]) {
                            sh(returnStatus: true, script: libraryResource('build_with_slackrepo.sh'))

                            writeFile(file: 'slackrepo_parse.rb', text: libraryResource('slackrepo_parse.rb'))

                            sh "LANG=en_US.UTF-8 ruby slackrepo_parse.rb '$JOB_NAME' 'tmp/$PROJECT/checkstyle.xml' 'tmp/$PROJECT/junit.xml' 'tmp/$PROJECT/build'"
                        }
                    }

                }

                junit allowEmptyResults: true, testResults: "tmp/${it}/junit.xml"
            }
        }
    } finally {
        recordIssues blameDisabled: true, enabledForFailure: true, tools: [checkStyle(id: 'slackrepo', name: 'Slackrepo', pattern: 'tmp/**/checkstyle.xml')]
        archiveArtifacts artifacts: 'log/**/*'
    }
}
