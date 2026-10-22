# Usage

sahsync copies and syncs files through a SystemAPI agent. Login is `sahconnect login`. The server and credentials come from the same config and environment as sahconnect: `SYSTEMAPI_URL`, and a token file from `sahconnect login` or `SYSTEMAPI_API_KEY`. A token file wins over the key and sahsync says so on stderr.

A remote is `HOST:PATH`. PATH is absolute, `~`, or `~/...`. The rules are in `docs/paths.md`.

## Output

stdout carries listings and sync plans. stderr carries one `audit op=OP path=PATH size=N sha256=HEX` line per real mutation, and errors.

A refusal prints one code word on stderr, such as `not_found`, `exists`, `root_invalid`, `root_denied`, `not_a_file`, `not_a_dir`, `symlink_refused`, `agent_unsupported`, `rate_limited`, `connect_failed`, `handshake_refused`, `name_collision`, `empty_source`, or `protocol_error`. The code words are the contract's (`sah-file-protocol.md` section 8) plus local ones for the same conditions.

Exit 0 is success, including a dry run whose real run would succeed. A download dry run that the real run would refuse prints its plan and then exits 1 with the same code word. Exit 1 is a refusal from the server, the agent, or the local filesystem. Exit 2 is a usage error or a path refused before any network call (`bad_path`, `bad_root`, `reserved_name`, `invalid_url`, a local directory given to `put`, a remote PATH ending in `/` given to `get`, a local file given to `sync`). The `method ssh` refusal is also exit 2.

## put

    sahsync put [--force] [--root] LOCAL HOST:PATH

Uploads one regular file. A PATH ending in `/` receives the local base name. LOCAL must not be a symlink or have a symlink parent. A directory is refused with `not_a_file`; use `sync`.

--force replaces an existing remote file. Without it an existing name is `exists`.

--root asks for a `file:root` ticket. The helper then runs as root. It needs the admin-only `file:root` scope and refuses `~`.

## get

    sahsync get [--force] [--root] HOST:PATH LOCAL

Downloads one regular file. LOCAL ending in `/`, or an existing directory, receives the remote base name. A remote directory is `not_a_file`; a PATH ending in `/` is refused before any call with `not_a_file`. Use `get -r`.

The file lands in a `.sahsync-<32 hex>.part` temp next to the destination, is checked against the remote sha256, then published.

--force replaces an existing local file (rename). Without it the publish is a link and an existing name is `exists`.

--root as for put.

## get -r

    sahsync get -r [--force] [--root] HOST:DIR LOCAL

Copies the contents of the remote directory DIR into the local directory LOCAL. It is `sync --from` with no plan on stdout and no `--delete`. LOCAL is created when it is missing; its parent must exist. Unlike scp, `get -r h:/srv/site ./copy` does not make `./copy/site`.

Files that are already equal are skipped. A remote file that differs from an existing local file needs `--force`. Without it the run is refused with `exists` before anything is written.

## ls

    sahsync ls [--root] HOST:PATH

Lists one directory. Each line is `TYPE MODE SIZE MTIME_NS NAME`, sorted by name. TYPE is `file`, `dir`, `symlink`, or `other`.

## sync (upload)

    sahsync sync [--create] [--delete] [--yes] [--dry-run] [--root] LOCAL HOST:DIR

Makes the remote directory DIR match the local directory LOCAL. The contents of LOCAL go into DIR. Each plan line is printed on stdout first: `put`, `mkdir`, `skip`, `delete`, `skip-symlink`, `conflict-symlink`, or `skip-other`, with `size=` and `sha256=` when known.

A file is copied when the size differs, or when the mtime differs and the sha256 differs. A changed remote file is replaced without `--force`; sync owns the destination.

--create makes DIR when it does not exist. Only the last component is created: its parent must already exist and must be allowed by the host's file policy for writing. Without --create a missing DIR is `root_invalid`. How it works: the agent opens the session root at session start and refuses a missing root with `root_invalid` (contract section 5.3). On that refusal, and only with --create, sahsync opens a second session on the parent directory and runs the same sync into the last component, making it with `mkdir` first. The plan then starts with `mkdir .`. This spends two tickets. When the parent is missing too, the second session also gets `root_invalid` and nothing is written. When DIR exists but is a file or a symlink, the second session refuses (`not_a_dir`, or the agent's `symlink_refused`). `~` and `/` have no parent and are never retried. For `~/sub`, the session root is `~` and `sub` is always created when missing, with or without --create.

--delete also removes remote entries that are not in LOCAL. Without --yes it prints the plan and changes nothing. A file is hashed again right before it is removed and is kept if it changed. A directory that still holds a `.sahsync-*.part` name is kept.

--yes lets --delete run.

--dry-run prints the plan and changes nothing. It wins over --yes. A dry run and the following real run print the same lines.

--root as for put.

## sync --from (download)

    sahsync sync --from [--force] [--delete] [--yes] [--dry-run] [--root] HOST:DIR LOCAL

Makes the local directory LOCAL match the remote directory DIR. The arguments keep source first, as in rsync. The plan lines are the upload ones with `get` in place of `put`. The session is always `file:read` (or `file:root` with --root): a download never writes the remote side.

LOCAL is created when it is missing. Its parent must exist. Symlinks above LOCAL are allowed: the parent of LOCAL is resolved once, so `/tmp/x` and `$TMPDIR/x` on macOS work. LOCAL itself must not be a symlink (`symlink_refused`), and nothing below it is ever followed. A remote DIR that is missing, or a `~/sub` that is missing, not a directory, or removed while it is being listed, is refused; it is never treated as an empty tree.

Every local change goes through one handle opened on LOCAL (Go's `os.Root`). A directory inside LOCAL that is swapped for a symlink after the plan cannot lead a write or a delete outside LOCAL, and a symlinked parent inside LOCAL is refused with `symlink_refused`.

Before anything is written, in a dry run too, the plan is checked. Any of these refuses the whole run and nothing is written:

- `name_collision`: two names differ but are equal after Unicode NFC and lower case, between two remote names or between a remote and a local name (`A.txt` and `a.txt`, `FOO.txt` and `foo.txt`, or the NFD and NFC spellings of `é`). On a case-insensitive filesystem such as APFS they would be one file. This is refused on case-sensitive filesystems too; rename one side.
- `not_a_dir` or `symlink_refused`: a file or directory would land under a local path that is a file or a symlink.
- `exists`: an existing local file would be replaced and --force is not set.
- `empty_source`: --delete would remove local entries while DIR has nothing to copy. A remote that lists empty by mistake therefore cannot empty LOCAL. Remove the local files by hand if that is the intent.

Each file is fetched with sequential `read` ops into a `.sahsync-<32 hex>.part` temp in its destination directory, checked against a remote `hash`, then published. Each copy prints `audit op=get`. A created local directory prints `audit op=local-mkdir`; a removed local entry prints `audit op=local-delete`.

Local modes do not copy the remote ones exactly. A file gets the remote mode with group and other write removed, then the umask, with owner read and write always on: remote 0777 becomes 0755 under umask 022, 0600 stays 0600, 0755 keeps its exec bits. A directory is the same with owner rwx. setuid, setgid and sticky are never set.

--force replaces existing local files that differ. New files and directories do not need --force.

--delete also removes local entries that are not in DIR: files, symlinks (the link, never the target), and then empty directories, deepest first. Without --yes it prints the plan and changes nothing. A file is checked again (size, mtime, sha256) right before removal and is kept if it changed. A local `.sahsync-*.part` name, and a local name the protocol cannot carry (one with `%`, `\` or a control character, shown as `skip-other`), is never removed, and neither is its parent.

--yes lets --delete run. There is no interactive prompt, as for upload.

--dry-run prints the plan and writes nothing, not even LOCAL. It wins over --yes. It runs the same checks as the real run and exits 1 when the real run would be refused.

--create is an upload flag. With --from it is a usage error. --force without --from is a usage error, since upload sync already replaces changed remote files.

## version

    sahsync version

Prints `sahsync 0.1.0`.

## Limits

The server issues at most 20 file tickets a minute per host and caller. Each command uses one ticket; `sync --create` that has to create uses two. Past the limit a command fails with `rate_limited`; wait a minute.

mtimes are not set on either side, so the next sync of a copied file finds a different mtime and hashes both sides. That costs a read of each file. It does not copy again.
