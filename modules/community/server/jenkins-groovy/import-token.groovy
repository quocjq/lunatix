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
for (int i = 0; i < 60; i++) {
    try {
        Class.forName("com.cloudbees.plugins.credentials.SystemCredentialsProvider")
        break
    } catch (ClassNotFoundException e) {
        if (i == 59) {
            println "import-token.groovy: credentials plugin not available after 60s; skipping (install credentials plugin)"
            return
        }
        Thread.sleep(1000)
    }
}

def scope = Class.forName("com.cloudbees.plugins.credentials.CredentialsScope")
def domain = Class.forName("com.cloudbees.plugins.credentials.domains.Domain")
def impl = Class.forName("com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl")
def providerCls = Class.forName("com.cloudbees.plugins.credentials.SystemCredentialsProvider")

def dom = domain.getMethod("global").invoke(null)
def provider = providerCls.getMethod("getInstance").invoke(null)
def store = provider.getStore()
if (store == null) {
    println "import-token.groovy: SystemCredentialsProvider store is null, skipping"
    return
}

// Remove existing credential with the same id (fresh each boot).
def existing = store.getCredentials(dom).find { it.getId() == credId }
if (existing != null) {
    store.removeCredentials(dom, existing)
}

def cred = impl.getConstructor(scope, String.class, String.class, String.class, String.class)
    .newInstance(scope.getField("GLOBAL").get(null), credId, "Forgejo deploy token (agenix)", credUser, token)
store.addCredentials(dom, cred)
providerCls.getMethod("save").invoke(provider)

println "import-token.groovy: upserted credential '$credId' ($credUser) from $tokenPath"
