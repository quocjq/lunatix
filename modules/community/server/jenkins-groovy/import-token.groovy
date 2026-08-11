// Seeds the Forgejo deploy credential from the agenix-decrypted token file
// into Jenkins' credential store. Runs at every Jenkins startup.
//
// The credentials-plugin may not be installed yet on first boot (fresh
// Jenkins ships no plugins). Wait for it: if it never appears, skip quietly —
// a wiped home self-heals once the plugin is present.

def tokenPath = "/run/agenix/forgejo-token"
def tokenFile = new File(tokenPath)

if (!tokenFile.exists()) {
    println "import-token.groovy: $tokenPath missing, skipping"
    return
}

def token = tokenFile.text.trim()
if (token.isEmpty()) {
    println "import-token.groovy: $tokenPath is empty, skipping"
    return
}

def credId = "forgejo-deploy"
def credUser = "lunixose"

// Wait up to ~60s for the credentials plugin to load (it boots after the
// core; a fresh Jenkins needs it installed first).
for (int i = 0; i < 60; i++) {
    try {
        Class.forName("com.cloudbees.plugins.credentials.CredentialsStore")
        break
    } catch (ClassNotFoundException e) {
        if (i == 59) {
            println "import-token.groovy: credentials plugin not available, skipping (install credentials plugin)"
            return
        }
        Thread.sleep(1000)
    }
}

import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList(
    com.cloudbees.plugins.credentials.CredentialsStore.class)[0]

// Replace an existing credential of the same id (keep it fresh each boot).
def existing = store.getCredentials(domain).find { it.id == credId }
if (existing != null) {
    store.removeCredentials(domain, existing)
}

def cred = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL, credId, "Forgejo deploy token (agenix)", credUser, token)
store.addCredentials(domain, cred)

println "import-token.groovy: upserted credential '$credId' ($credUser) from $tokenPath"
