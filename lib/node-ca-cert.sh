# Discover the OS's merged CA bundle and export it as NODE_EXTRA_CA_CERTS.
#
# Node.js bundles its own CA store and ignores the system one, so it can't
# verify TLS through a corporate TLS-inspecting proxy (e.g. AMD's Zscaler,
# which re-signs HTTPS traffic including registry.npmjs.org with an internal
# cert chain) even after update-ca-certificates trusts it system-wide. Point
# Node at the OS's actual merged trust store (which already includes any
# such custom CA once update-ca-certificates has run) instead of hardcoding
# one specific cert's filename or disabling verification -- this keeps
# working unchanged regardless of which CA, filename, or proxy is involved on
# a given machine, and stays a no-op (Node's own default trust applies) on
# machines with no such proxy at all.
#
# No-op if NODE_EXTRA_CA_CERTS is already set. Uses portable `[ ]`/`for` so
# this sources cleanly from both zsh (.zshrc) and bash (install.sh, min.sh).
if [ -z "${NODE_EXTRA_CA_CERTS:-}" ]; then
    for _ca_bundle in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt; do
        if [ -f "$_ca_bundle" ]; then
            export NODE_EXTRA_CA_CERTS="$_ca_bundle"
            break
        fi
    done
    unset _ca_bundle
fi
