Step 1 — Prepare 1.0.3

```
./scripts/prepare-release.sh 1.0.3
```

The script should finish by showing:

```
Previous version: 1.0.2
New version: 1.0.3
Release date: 2026-08-28
```

Step 2 — Review

Very important:

```
git diff -- CHANGELOG.md v4l2loopback.spec
```

And also:

```
git diff --check
```

Specifically check:

```
grep '^Version:' v4l2loopback.spec
```

It should return:

Version: 1.0.3

And:

```
grep -n '## \[1.0.3\]' CHANGELOG.md
```

It should find:

```
## [1.0.3] - 2026-08-28
Step 3 — Commit release
git add CHANGELOG.md v4l2loopback.spec
git commit -m "chore: prepare v1.0.3 release"
```

Step 4 — push main

```
git push origin main
```

This is important.

It should produce:

main
 │
 ├── ShellCheck ✅
 │
 └── RPM Build  ✅

For this new 1.0.3 commit.

The actions that have already occurred tell us that the infrastructure is working, but after changing:

Version: 1.0.2
↓
Version: 1.0.3

it's advisable to specifically validate the release commit.

Step 5 — verify before the tag

When these actions occur:

```
git status
```

should be clean.

Next:

```
git log -1 --oneline
```

It should look something like this:

```
abcdef1 chore: prepare v1.0.3 release
```

And check that the local and remote commits are exactly the same:

```
git rev-parse HEAD
git rev-parse origin/main
```

They should produce the same SHA.

Step 6 — Create the tag

The script currently recommends:

```
git tag -a v1.0.3 -m "v1.0.3"
```

That's fine.

If you want to keep signed GPG tags:

```
git tag -s v1.0.3 -m "v1.0.3"
```

Then:

```
git show v1.0.3
```

Step 7 — PUSHING THE TAG = PUBLISHING

```
git push origin v1.0.3
```

This is what happens:

```
git push origin v1.0.3
```

This is what happens:

                 git push origin v1.0.3
                          │
                          ▼
                 push tag v1.0.3
                          │
                          ▼
                 ┌─────────────────┐
                 │   release.yml   │
                 └────────┬────────┘
                          │
                          ├── validate tag
                          │
                          ├── SPEC == 1.0.3
                          │
                          ├── CHANGELOG == 1.0.3
                          │
                          ├── extract notes
                          │
                          ├── verify remote tag
                          │
                          ▼
                 GitHub Release
                      v1.0.3

Paso 8 — check

```
gh run list --limit 10
```

and then:

```
gh release view v1.0.3
```

And:

```
git ls-remote --tags origin v1.0.3
```

Review:

                    RELEASE v1.0.3

Infrastructure
    │
    ├── shellcheck.yml ........ ✅
    ├── rpm-build.yml ......... ✅
    ├── release.yml ........... ✅ reviewed
    └── prepare-release.sh .... ✅ reviewed
                                │
                                ▼
                   ./prepare-release.sh 1.0.3
                                │
                                ▼
                       review git diff
                                │
                                ▼
                      commit release
                                │
                                ▼
                         push main
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
               ShellCheck ✅            RPM Build ✅
                    └───────────┬───────────┘
                                ▼
                         tag v1.0.3
                                │
                                ▼
                    git push origin v1.0.3
                                │
                                ▼
                         release.yml
                                │
                                ▼
                    GitHub Release v1.0.3
