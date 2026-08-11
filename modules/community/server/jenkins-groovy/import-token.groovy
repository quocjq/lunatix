// Seeds the Forgejo deploy credential from the agenix-decrypted token file
// into Jenkins' credential store. Idempotent: creates or updates the
// `forgejo-deploy` credential. Runs at every Jenkins startup.
//
// The token file is /run/agenix/forgejo-token (decrypted by agenix, owner
// jenkins). Read it here so the credential survives a wiped $JENKINS_HOME.

import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.CredentialsProvider
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl

def tokenPath = "/run/agenix/forgejo-token"
def tokenFile = new File(tokenPath)

if (!tokenFile.exists()) {
    println "import-token.groovy: $tokenPath missing, skipping"
    return
}

def token = tokenFile.text.trim()
def credId = "forgejo-deploy"
def credUser = "lunixose"
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
