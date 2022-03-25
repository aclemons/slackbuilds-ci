#!/usr/bin/env groovy

// Copyright 2022 Andrew Clemons, Wellington New Zealand
// All rights reserved.
//
// Redistribution and use of this script, with or without modification, is
// permitted provided that the following conditions are met:
//
// 1. Redistributions of this script must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
//  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[x86_64: 'slackware64', x86: 'slackware', arm: 'slackwarearm'].each { arch, name ->
    pipelineJob("slackbuilds.org-15.0-${name.capitalize()}") {
        definition {
            cpsScm {
                lightweight(true)

                scm {
                    github('aclemons/slackbuilds-ci', 'master')
                }

                scriptPath('Jenkinsfile')
            }
        }

        description("Mass build slackbuilds.org for ${name.capitalize()}-15.0.")

        environmentVariables {
            env('SLACKREPO_DIR', '/var/lib/jenkins/caches/slackrepo/15.0/SBo')
            env('SLACKREPO_DOCKER_IMAGE', "aclemons/slackrepo:15.0-${arch}")
            env('OPT_REPO', 'SBo')
            env('PACKAGE_NAME', 'academic accessibility audio business desktop development games gis graphics ham haskell libraries misc multimedia network office perl python ruby system')
            env('BRANCH', '15.0')

            if (arch == 'x86') {
                env('SETARCH', 'linux32')
            }
        }

        logRotator {
            numToKeep(5)
        }

        properties {
            disableConcurrentBuilds()
        }
    }
}

pipelineJob("slackbuilds.org-15.0-shellcheck") {
    definition {
        cpsScm {
            lightweight(true)

            scm {
                github('aclemons/slackbuilds-ci', 'master')
            }

            scriptPath('Jenkinsfile.shellcheck')
        }
    }

    description('Run shellcheck on all scripts from slackbuilds.org for 15.0.')

    environmentVariables {
        env('BRANCH', '15.0')
    }

    logRotator {
        numToKeep(5)
    }

    properties {
        disableConcurrentBuilds()
    }
}

pipelineJob("slackbuilds.org-15.0-sbolint") {
    definition {
        cpsScm {
            lightweight(true)

            scm {
                github('aclemons/slackbuilds-ci', 'master')
            }

            scriptPath('Jenkinsfile.sbolint')
        }
    }

    description('Run sbolint on all scripts from slackbuilds.org for 15.0.')

    environmentVariables {
        env('BRANCH', '15.0')
    }

    logRotator {
        numToKeep(5)
    }

    properties {
        disableConcurrentBuilds()
    }
}
