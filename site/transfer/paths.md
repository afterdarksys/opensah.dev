# Paths and what a copy keeps

Unix only. Local opens use `O_NOFOLLOW`.

## Remote paths

A remote is `HOST:PATH`. The host is `[A-Za-z0-9._-]{1,253}`. The path is absolute (`/srv/app/note.txt`), `~`, or `~/...`.

`~` and `~/` are the session root `~` and the relative path `.`. `~/site/a.txt` is root `~` and relative `site/a.txt`. An absolute file's session root is its parent. A directory path (a trailing slash, or `ls` / `sync`) is the session root and the relative path `.`.

`..`, `.`, `\`, NUL, other controls, and a component that contains `%` are refused before any HTTP. `foo..bar` and `...` are legal names. `/etc/../../shadow` is `bad_root` because the walk sees `..` before cleaning.

`--root` asks for `purpose=file:root` and refuses `~`. Without `--root`, a read is `file:read` and a write is `file:write`.

A name that starts with `.sahsync-` and ends with `.part` is reserved. The client will not upload or download it. Sync prints `skip` and does not delete a directory that still contains one.

## Local writes

A download is created as `.sahsync-<32 hex>.part` in the destination directory (`O_EXCL|O_NOFOLLOW`, mode `0600`). The file is fsynced, chmod'd, then published. Without `--force` the publish is `link` and an existing name is `exists` (the temp is removed, including when the name is a symlink). With `--force` the publish is `rename`. A parent that is a symlink is `symlink_refused`. On macOS `/tmp` and `/var` are symlinks, so a destination under them is refused. Use a path with no symlink component, such as `/private/tmp/...`.

A put refuses a symlink source and a symlink parent. A directory is `not_a_file`; use `sync`.

## What is preserved

The mode is `mode & 0777`, then bits below `0600` are OR'd with `0600`. Owner read and write stay on. Exec bits at or above that floor stay. setuid, setgid, and the sticky bit are cleared. Example: `04755` becomes `0755`, `0100` becomes `0700`, `0000` becomes `0600`.

The client does not chown. It does not set mtime. Sync compares size, then mtime, then sha256, and a transfer is the whole file. Equal size and equal mtime skip the hash. Symlinks are not copied (`skip-symlink` or `conflict-symlink`). A file where the other side is a directory is `skip` and is left alone.

Sync runs both ways. `sync --from` and `get -r` apply the same temp-then-publish rule to every file. Unlike `get`, they allow symlinks above LOCAL (the parent is resolved once) and refuse a symlink at LOCAL or anywhere below it. All of their local changes go through an `os.Root` on LOCAL. A downloaded file's mode drops group and other write and applies the umask (`get` does the same); see `docs/usage.md`. A download never sets a local mtime, so a later sync hashes both sides of a copied file once more.

`sync --create HOST:/a/b` opens a session on `/a` and makes `b` only when the session on `/a/b` is refused with `root_invalid`. `/a` must exist and must be in the host's write policy.
