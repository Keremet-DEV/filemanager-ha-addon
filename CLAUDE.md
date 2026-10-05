# sandyk-ha-addon

Home Assistant add-on repository of the Sandyk project: the server image
(Keremet-DEV/sandyk-server) plus run.sh, which maps the add-on options to FM_* settings.
App: Keremet-DEV/sandyk-app. Discussion with the owner is in Russian; code, comments and
commits in English.

- Keep the server version the same in sandyk/config.yaml, build.yaml and Dockerfile.
- run.sh runs in the server's Alpine image (busybox sh, jq, curl, su-exec); test with
  scripts/test.sh (Docker only). CI on the org's self-hosted runners.
