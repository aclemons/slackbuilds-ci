def call() {
    try {
      sh('wget -q https://slackbuilds.org/uid_gid.txt') // trusting the contents over https here :)
      sh(returnStatus: true, script: libraryResource('uid_gid.sh'))
    } finally {
      sh("rm -rf uid_gid.txt")
    }
}
