def call() {
    def userId = sh(returnStdout: true, script: '#!/bin/sh -e\nid -u jenkins').trim()
    def groupId = sh(returnStdout: true, script: '#!/bin/sh -e\nid -g jenkins').trim()

    def buildArch = env.BUILD_ARCH
    if (buildArch == null) {
        buildArch = ''
    }

    def optRepo = env.OPT_REPO

    if (optRepo == null) {
        optRepo = 'SBo'
    }

    // re-init log/tmp
    sh 'rm -rf log tmp'
    dir ('log') {
        sh '#!/bin/sh -e\necho "Created log directory: $(pwd)"'
    }

    try {

      docker.image(env.SLACKREPO_DOCKER_IMAGE).inside("-u 0 --privileged -v ${env.SLACKREPO_DIR}:/var/lib/slackrepo/${optRepo}") {
        ansiColor('xterm') {
          if ("true".equals(env.SEED_UID_GID)) {
            createAllUsersAndGroups()
          }

          withEnv(["JENKINSUID=${userId}", "JENKINSGUID=${groupId}", "BUILD_ARCH=${buildArch}", "OPT_REPO=${optRepo}", "UPDATE=true"]) {
            sh(returnStatus: true, script: libraryResource('build_with_slackrepo.sh'))

              writeFile(file: 'slackrepo_parse.rb', text: libraryResource('slackrepo_parse.rb'))

              sh "LANG=en_US.UTF-8 ruby slackrepo_parse.rb '$JOB_NAME' 'tmp/checkstyle.xml' 'tmp/junit.xml' 'tmp/build'"
          }
        }

      }

      junit allowEmptyResults: true, testResults: "tmp/junit.xml"
    } finally {
        recordIssues blameDisabled: true, enabledForFailure: true, tools: [checkStyle(id: 'slackrepo', name: 'Slackrepo', pattern: 'tmp/**/checkstyle.xml')]
        archiveArtifacts artifacts: 'log/**/*'
    }
}
