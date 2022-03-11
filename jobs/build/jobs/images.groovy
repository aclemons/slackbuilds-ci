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

['14.2', '15.0', 'current'].each { release ->
    [x86_64: 'slackware64', x86: 'slackware', arm: 'slackwarearm'].each { arch, name ->
        pipelineJob("docker-${name}-${release}-base") {
            definition {
                cpsScm {
                    lightweight(true)

                    scm {
                        github('aclemons/slackware-dockerfiles', 'master')
                    }

                    scriptPath("${name}-${release}/Jenkinsfile")
                }
            }

            description("Builds a docker image of a base install of ${name.capitalize()}-${release}.")

            environmentVariables(
                DOCKER_IMAGE: "aclemons/slackware:${release}-${arch}-base"
            )

            properties {
                disableConcurrentBuilds()
            }
        }

        pipelineJob("docker-${name}-${release}-full") {
            definition {
                cpsScm {
                    lightweight(true)

                    scm {
                        github('aclemons/slackware-dockerfiles', 'master')
                    }

                    scriptPath('Jenkinsfile')
                }
            }

            description("Builds a docker image for using as a build environment for ${name.capitalize()}-${release}.")

            environmentVariables(
                DOCKER_IMAGE: "aclemons/slackware:${release}-${arch}-full",
                BASE_IMAGE: "aclemons/slackware:${release}-${arch}-base",
                LOCAL_MIRROR: "/var/lib/jenkins/caches/slackware/${name}-${release}"
            )

            properties {
                disableConcurrentBuilds()
            }
        }

        pipelineJob("docker-${name}-${release}-slackrepo") {
            definition {
                cpsScm {
                    lightweight(true)

                    scm {
                        github('aclemons/slackware-dockerfiles', 'master')
                    }

                    scriptPath('slackrepo/Jenkinsfile')
                }
            }

            description("Builds a docker image for using slackrepo on ${name.capitalize()}-${release}.")

            environmentVariables(
                DOCKER_IMAGE: "aclemons/slackrepo:${release}-${arch}",
                BASE_IMAGE: "aclemons/slackware:${release}-${arch}-full",
                NO_CACHE: 'true'
            )

            properties {
                disableConcurrentBuilds()
            }
        }
    }
}
