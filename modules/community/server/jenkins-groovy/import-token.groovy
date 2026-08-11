// Seeds the Forgejo deploy credential from the agenix-decrypted token file
// into Jenkins' credential store. Runs at every Jenkins startup.
//
// Fresh Jenkins ships no plugins; the credentials-plugin classes don't exist
// at compile time, so ALL references are reflective (no top-level imports —
// those fail the groovy compile before we can check availability).

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

// Wait up to ~60s for the credentials plugin to load (it boots after core;
// a fresh Jenkins needs it installed first).
def cls = null
for (int i = 0; i < 60; i++) {
    try {
        cls = Class.forName("com.cloudbees.plugins.credentials.CredentialsStore")
        break
    } catch (ClassNotFoundException e) {
        if (i == 59) {
            println "import-token.groovy: credentials plugin not available after 60s; skipping (install credentials plugin)"
            return
        }
        Thread.sleep(1000)
    }
}

def jenkins = jenkins.model.Jenkins.instance
def scope = Class.forName("com.cloudbees.plugins.credentials.CredentialsScope")
def domain = Class.forName("com.cloudbees.plugins.credentials.domains.Domain")
def impl = Class.forName("com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl")
def storeCls = Class.forName("com.cloudbees.plugins.credentials.CredentialsStore")

// Domain.global() and store retrieval via getExtensionList.
def dom = domain.getMethod("global").invoke(null)
def store = jenkins.getExtensionList(storeCls)[0]

// Remove existing credential with the same id (fresh each boot).
def existing = store.getCredentials(dom).find { it.getId() == credId }
if (existing != null) {
    store.removeCredentials(dom, existing)
}

def cred = impl.getConstructor(scope, String.class, String.class, String.class, String.class)
    .newInstance(scope.getField("GLOBAL").get(null), credId, "Forgejo deploy token (agenix)", credUser, token)
store.addCredentials(dom, cred)

println "import-token.groovy: upserted credential '$credId' ($credUser) from $tokenPath"
