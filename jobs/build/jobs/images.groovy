#!/usr/bin/env groovy

// Copyright 2022 Andrew Clemons, Wellington New Zealand
// Copyright 2022 Andrew Clemons, Tokyo Japan
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
    [x86_64: 'slackware64', x86: 'slackware', arm: 'slackwarearm', aarch64: 'slackwareaarch64'].each { arch, name ->
        if (arch == 'aarch64' && release != 'current') {
            return
        }

        if (arch == 'arm' && release == 'current') {
            return
        }

        def dockerArch = "linux/${arch}"
        if (arch == 'x86_64') {
            dockerArch = "linux/amd64"
        } else if (arch == 'x86') {
            dockerArch = "linux/386"
        } else if (arch == 'arm') {
            if (arch == 'arm' && release == '15.0') {
                dockerArch = "linux/arm/v7"
            } else {
                dockerArch = "linux/arm/v5"
            }
        } else if (arch == 'aarch64') {
            dockerArch = "linux/arm64/v8"
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
                BASE_IMAGE: "aclemons/slackware:${release}-full",
                NO_CACHE: 'true',
                PLATFORM: "${dockerArch}"
            )

            logRotator {
                numToKeep(5)
            }

            properties {
                disableConcurrentBuilds()
            }
        }
    }
}
