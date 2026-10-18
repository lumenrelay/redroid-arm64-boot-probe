# redroid arm64 boot probe

Disposable research workflow. It boots a pinned `redroid/redroid` Android 16 arm64 image on a GitHub-hosted `ubuntu-24.04-arm` runner with privileged Docker, records kernel binder/memfd facts, boots twice, restarts, verifies a sentinel file on a persisted `/data`, and idles for a configurable number of minutes while sampling container stats.

It installs no apps, adds no Google services, and signs in to nothing. ADB is bound to 127.0.0.1 only. All evidence is uploaded as a workflow artifact.
