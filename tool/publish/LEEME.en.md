# Exporting the public repository

[Español](LEEME.md)

Requirements: Git, a POSIX shell (Git Bash on Windows or `sh` on macOS), and
Python 3.9 or later, with no additional packages. From the repository root:

```sh
sh tool/publish/export_public.sh HEAD /empty/path/cuadrante-public
```

The destination must be outside the source repository and empty, including
hidden files. Its path must not contain symlinks. Missing directories are created.
The source repository is unchanged. The exporter makes no network calls.

To override the interpreter and public identity:

```sh
PUBLIC_PYTHON=python3 PUBLIC_AUTHOR_NAME='Your name' \
PUBLIC_AUTHOR_EMAIL='public@example.org' \
sh tool/publish/export_public.sh COMMIT /empty/path/cuadrante-public
```

The interpreter defaults to `python` if available, otherwise `python3`. In Git
Bash, use Windows paths with `/` for a fully qualified `PUBLIC_PYTHON` executable.
Both author and committer default to Daniel Mont Ferrandiz `<dev@mainshai.com>`.
The new `main` branch has one commit, titled “Initial public release of Cuadrante” (commits in the public repo are in English),
without remotes, tags or private history. Nothing is pushed.

## Selection policy

The checked-out exporter's `allowlist.txt` defines the policy: use the reviewed
version for your candidate. Each line is a POSIX relative path or a Python
`fnmatch` pattern (`*` also matches `/`); lines starting with `#` are comments.
The initial policy lists **individual reviewed files**, inventoried with
`git ls-files`. New files require an explicit addition.

The exporter resolves the commit, inventories it with `git ls-tree`, then streams
`git archive`. Only selected entries from that commit are written; worktree files,
ignored files and uncommitted changes are never copied. Selected symlinks and
submodules fail validation, as do missing entries caused by `export-ignore`.

Included: Flutter and native sources, generated files, tests, synthetic fixtures,
assets, portable tools and icons, CI, README, licences, security documents, legal
web pages, public graphics and technical contracts. Public contribution rules
are in `CONTRIBUTING.md` and `CONTRIBUTING.es.md`.

Excluded:

| Files or group | Reason |
|---|---|
| `.mcp.json`, `.claude/`, `.shots/`, `.handoff.md`, `.plan-gratis.md`, `CLAUDE.md`, `AGENTS.md` | Internal configuration and agent instructions |
| `docs/handoff.md`, `preguntas.md`, `analisis-mercado.md`, `paridad.md`, `auditoria-*`, `qa-hallazgos/` | Private handoffs, decisions, research and QA evidence |
| `docs/propuestas-diseno.md` | Internal decisions and references to other products |
| `docs/plan-de-pruebas.md`, `plan-publicacion.md`, `probar-y-pendiente.md`, `roadmap.md` | Internal campaigns and schedule; some technical contracts retain historical references to these documents |
| `tool/qa/manual/PROBADOR.md`, `tool/qa/upgrade_android.sh` | Local campaign and upgrades from private releases |
| `tool/release_android.sh` | Fixed local directory, history-based versioning, development signing and private publishing; requires separate review |
| `app/android/gradle/wrapper/gradle-wrapper.jar` | Binary outside approved locations; Flutter 3.47.7 restores missing wrapper files from its cache when building Android |
| Logs, APK/AAB, QA screenshots, keys and personal backups | Neither public sources nor synthetic fixtures |

Direct `./gradlew` use requires restoring the wrapper first; use `flutter build apk`
as the build entry point. Dart tests and screenshot generation do not read excluded
documents. The holiday generator and its optional test can still use a sibling
Mochila checkout; synthetic tests and shipped assets are self-contained. Full
holiday-source reproducibility is a separate task.

## Validation and limits

Names and bytes are checked before creating Git: personal Windows/macOS paths,
the local development identifier, private files, caches, logs, APKs, `.env*`,
`*.env`, `key.properties`, `local.properties`, keystores, private keys (`.p8`,
`.p12`, `.pem`, `.key`, `.mobileprovision`), `google-services.json`,
`GoogleService-Info.plist` and `secrets.*`. Private key markers,
GitHub/OpenAI tokens and AWS access keys are rejected, as well as Google API
keys (`AIza…`), live Stripe keys (`sk_live…`), Slack tokens (`xox…`), RevenueCat
keys (`appl…`, `goog…`), JWTs (three base64url segments separated by dots, the
first one starts with `eyJ…` and the payload may be `e30`) and
`storePassword`/`keyPassword` assignments in JSON, YAML, Gradle or Groovy.

No `@gmail.com` address is accepted, nor the author email of the source
repository. A domain that only begins with `gmail.com` is not a Gmail address
and is accepted. That email is read at runtime with `git config user.email` and is
never written in the code: the exporter adapts to whoever signs, without
leaving the address anywhere.

The effective attributes of every exported file are checked
(`git check-attr export-subst export-ignore`), the ones Git applies when it
archives: the `.gitattributes` of the commit plus
`$GIT_DIR/info/attributes`, which is not versioned. The export fails only when
the attribute is active; a disabled one (`-export-ignore`) or a commented line
changes nothing.

The exported bytes are compared with the blob of the commit. Only the line
ending difference that Git applies with the `eol` attribute is allowed; any
other rewrite, such as the one of `export-subst`, fails the export.

Binaries are only accepted under `app/assets/`, `app/test/`,
`docs/readme/`, or native PNG icons and icon previews. Compressed gzip/zip
`.cuadrante` payloads are scanned too.

The local identifier is also rejected inside public GitHub or GitHub Pages URLs.
There is no implicit exception for links: a candidate retaining that identity
in its README or website fails export. Resolve this policy explicitly before
approving the first public copy.

Files are read back before creating the commit in a temporary sibling directory.
The resulting Git repository must track exactly the selection, with one commit,
no remotes and no pending changes. A validation failure leaves an empty destination
and removes only this invocation's temporary staging directory. A nonempty
destination is never emptied or overwritten. Errors do not print suspected
secret values or source lines.

Pattern checks do not establish licensing, data provenance, image metadata
privacy or the absolute absence of secrets. The lead must review the exact tree,
images and final identity before any publication. Publishing is a separate step.

## Reproduce validation

```sh
python -B tool/publish/test_export_public.py
sh tool/publish/export_public.sh HEAD /empty/path/cuadrante-public
cd /empty/path/cuadrante-public
python -B web/legal/test_legal.py
cd app
flutter pub get
flutter gen-l10n
flutter analyze
TZ=Europe/Madrid flutter test
```

On Windows, use the Madrid system time zone and `flutter test` without `TZ`.
All candidate changes must be committed: exporting with a dirty worktree does
**not** include those changes. If an agent cannot commit its branch, the receiving
lead must commit and export `HEAD` again before approving the final candidate.

## Updating the public repository

The exporter always creates a new single-commit repository. To publish changes to
`dferrandizmont/cuadrante` while keeping its history (first done on 27-Oct-2026):

1. Export `HEAD` to an empty folder: `sh tool/publish/export_public.sh HEAD ../cq-public-export`.
   If a check fails, fix it in the private repository and export again.
2. In the public clone (`../cuadrante-public`, up to date with `origin/main`), replace the whole tree:
   `git rm -r -q --cached .`, delete everything except `.git`, extract the export with
   `(cd ../cq-public-export && git archive HEAD) | tar -x -C .`, then `git add -A`.
3. Commit **in English** with the public identity:
   `git -c user.name="Daniel Mont Ferrandiz" -c user.email="dev@mainshai.com" commit -m "<summary>"`.
4. `git push origin main` (with the owner's go-ahead) and delete `../cq-public-export`.

Public releases carry the APKs signed with the upload key (`docs/release-signing.md`), with
`SHA256SUMS.txt` and the certificate SHA-256 fingerprint in the notes, in Spanish and English.
