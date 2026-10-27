"""Export a committed tree using the checked-out, reviewed allowlist. No network."""

import contextlib
import fnmatch
import gzip
import io
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tarfile
import tempfile
import zipfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
# Disable local/global Git programs, attributes, filters, identity and templates.
# Never edit the source repository's configuration or hooks.
GIT_ENV = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
GIT_ENV.update({
    'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull,
    'GIT_ATTR_NOSYSTEM': '1', 'GIT_TERMINAL_PROMPT': '0',
    'GIT_CONFIG_COUNT': '6',
    'GIT_CONFIG_KEY_0': 'core.fsmonitor', 'GIT_CONFIG_VALUE_0': 'false',
    'GIT_CONFIG_KEY_1': 'core.hooksPath', 'GIT_CONFIG_VALUE_1': os.devnull,
    'GIT_CONFIG_KEY_2': 'core.pager', 'GIT_CONFIG_VALUE_2': 'cat',
    'GIT_CONFIG_KEY_3': 'diff.external', 'GIT_CONFIG_VALUE_3': '',
    'GIT_CONFIG_KEY_4': 'core.attributesFile', 'GIT_CONFIG_VALUE_4': os.devnull,
    'GIT_CONFIG_KEY_5': 'safe.directory', 'GIT_CONFIG_VALUE_5': str(ROOT),
})
PERSONAL = re.compile(rb'[A-Z]:[/\\]Users|/' + b'Users/|' + b'df' + b'err(?!andizmont)', re.I)  # the local user folder, not the public GitHub account
# A Gmail mailbox, but not a longer domain that only begins with "gmail.com":
# the two lookarounds forbid a name that continues with letters or with a dot
# followed by another domain label.
GMAIL = re.compile(
    rb'[A-Za-z0-9._%+\-]+@gmail\.com(?![A-Za-z0-9\-])(?!\.[A-Za-z0-9\-])', re.I)
SECRETS = re.compile(
    rb'-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----|'
    rb'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|'
    rb'sk-[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16}|'
    # The markers are written with a character class so that this very file
    # does not match itself: the exporter scans its own source too.
    rb'AIza[0-9A-Za-z_-]{35}|sk[_]live[_]|xox[abposr]-|appl[_]|goog[_]|'
    # A JSON web token: base64url segments separated by dots, the first one
    # always starts with "eyJ". The payload may be the short "e30".
    rb'eyJ[A-Za-z0-9_-]{2,}\.[A-Za-z0-9_-]{2,}(?:\.[A-Za-z0-9_-]*)?|'
    # A signing password in JSON, YAML, Gradle or Groovy: the key can be
    # quoted and the value can follow with "=", ":" or a parenthesis. Reading
    # it from the gitignored key.properties (build.gradle.kts) is not a value.
    rb'["\']?(?:store|key)[Pp]assword["\']?\s*(?:=|:|\(|\s+["\'])'
    rb'(?!\s*keyProperties\.getProperty\(["\'](?:store|key)[Pp]assword["\']\))'
)
INTERNAL = {
    'docs/handoff.md', 'docs/preguntas.md', 'docs/analisis-mercado.md',
    'docs/paridad.md', 'docs/propuestas-diseno.md', '.plan-gratis.md',
}
INTERNAL_PARTS = {
    '.git', '.mcp.json', '.claude', '.shots', '.handoff.md', 'CLAUDE.md',
    'AGENTS.md', 'qa-hallazgos', '.dart_tool', '__pycache__', 'node_modules',
    'build', 'dist', '.DS_Store', 'Thumbs.db',
}
PRIVATE_SUFFIXES = {
    '.jks', '.keystore', '.p12', '.pfx', '.p8', '.pem', '.key', '.mobileprovision',
    '.apk', '.aab', '.log', '.shifter',
}
PRIVATE_NAMES = {
    'key.properties', 'local.properties', 'google-services.json',
    'googleservice-info.plist',
}


def git(*args, cwd=None, env=None):
    return subprocess.check_output(
        ['git', *args], cwd=cwd or ROOT, env=env or GIT_ENV, stderr=subprocess.PIPE,
    )


def read_config_email():
    """The source repository's author email, read from Git at runtime.

    It is never written in this file: the export adapts to whoever commits.
    The Git environment is read as the committer sees it, so the identity of
    the repository (local or global configuration) is the one that applies.
    """
    env = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
    env['GIT_TERMINAL_PROMPT'] = '0'
    try:
        raw = subprocess.check_output(
            ['git', 'config', '--get', 'user.email'], cwd=ROOT, env=env,
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.SubprocessError):
        return ''
    return raw.decode('utf-8', 'replace').strip()


PRIVATE_EMAILS = set()


def load_private_emails():
    """Collect the identities that must never reach the public copy."""
    PRIVATE_EMAILS.clear()
    value = read_config_email()
    if value:
        PRIVATE_EMAILS.add(value.lower())
    return PRIVATE_EMAILS


def private_email_in(data):
    """True when the bytes carry the private repository's author email."""
    if not PRIVATE_EMAILS:
        return False
    lowered = data.lower()
    return any(email.encode('utf-8') in lowered for email in PRIVATE_EMAILS)


def forbidden(name):
    path = PurePosixPath(name)
    lower = name.lower()
    return (
        lower in {p.lower() for p in INTERNAL}
        or bool({p.lower() for p in path.parts} & {p.lower() for p in INTERNAL_PARTS})
        or any(p.lower().startswith('.env') for p in path.parts)
        or path.name.lower() in PRIVATE_NAMES
        or path.suffix.lower() in PRIVATE_SUFFIXES
        or path.suffix.lower() == '.env'
        or path.name.lower().startswith('secrets.')
        or lower.startswith('docs/auditoria-')
        or any(p.lower() in {'logs', 'screenshots', 'qa-screenshots'} for p in path.parts)
    )


def safe_name(name):
    path = PurePosixPath(name)
    return (
        not path.is_absolute() and name == path.as_posix()
        and all(p not in {'', '.', '..'} for p in path.parts)
        and not re.search(r'[\\:\x00-\x1f\x7f]', name)
    )


def binary_allowed(name):
    return name.startswith(('app/assets/', 'docs/readme/', 'app/test/')) or (
        name.lower().endswith('.png') and (
            name.startswith('tool/icon/preview/')
            or name.startswith('app/ios/Runner/Assets.xcassets/')
            or re.match(r'app/android/app/src/main/res/(?:drawable|mipmap)[^/]*/', name)
        )
    )


def scan_bytes(name, data):
    # Report the path and type only: never print the matching secret or line.
    if PERSONAL.search(data):
        raise ValueError(f'Ruta o identificador personal: {name}')
    if GMAIL.search(data):
        raise ValueError(f'Correo de Gmail no permitido: {name}')
    if private_email_in(data):
        raise ValueError(f'Correo del autor del repositorio no permitido: {name}')
    if SECRETS.search(data):
        raise ValueError(f'Posible secreto: {name}')


def scan_file(name, data):
    if forbidden(name):
        raise ValueError(f'Fichero prohibido: {name}')
    scan_bytes(name, name.encode('utf-8'))
    scan_bytes(name, data)
    try:
        text = data.decode('utf-8')
        binary = any(ord(c) < 32 and c not in '\t\n\r\f' for c in text)
    except UnicodeDecodeError:
        binary = True
    if binary and not binary_allowed(name):
        raise ValueError(f'Binario fuera de las zonas permitidas: {name}')
    if name.endswith('.cuadrante'):
        # Compatibility fixtures contain compressed JSON; scan the payload too.
        if len(data) > 4 * 1024 * 1024:
            raise ValueError(f'Fixture demasiado grande: {name}')
        if data.startswith(b'\x1f\x8b'):
            with gzip.GzipFile(fileobj=io.BytesIO(data)) as stream:
                payload = stream.read(16 * 1024 * 1024 + 1)
            if len(payload) > 16 * 1024 * 1024:
                raise ValueError(f'Fixture expandido demasiado grande: {name}')
            scan_bytes(name + ' (gzip)', payload)
        elif zipfile.is_zipfile(io.BytesIO(data)):
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                if sum(m.file_size for m in archive.infolist()) > 16 * 1024 * 1024:
                    raise ValueError(f'Fixture expandido demasiado grande: {name}')
                for member in archive.infolist():
                    scan_bytes(name + ' (zip)', member.filename.encode('utf-8'))
                    scan_bytes(name + ' (zip)', archive.read(member))
        else:
            # An unknown binary container cannot be certified by a text scan.
            data.decode('utf-8')


@contextlib.contextmanager
def commit_index(commit):
    """A temporary index with the tree of the commit.

    The attributes are read from it, so the `.gitattributes` of the commit are
    the ones that apply and not the ones of a dirty working tree.
    """
    with tempfile.TemporaryDirectory(prefix='cuadrante-indice-') as temporary:
        env = dict(GIT_ENV, GIT_INDEX_FILE=str(Path(temporary) / 'indice'))
        git('read-tree', commit, env=env)
        yield env


def check_export_attributes(commit, names):
    """Refuse a commit whose attributes would rewrite or hide an exported file.

    `git archive` applies `export-subst` and `export-ignore` to the whole tree,
    so a file that is rewritten or hidden would never be the one that was
    reviewed. The effective attributes of every exported file are the ones
    Git applies when it archives: the `.gitattributes` of the commit plus
    `$GIT_DIR/info/attributes`, which Git applies even when it is not
    versioned. Only an active attribute (`set`) is refused: a disabled one
    (`-export-ignore`) and a commented line change nothing.
    """
    with commit_index(commit) as env:
        request = b''.join(name.encode('utf-8') + b'\0' for name in names)
        process = subprocess.run(
            ['git', 'check-attr', '--cached', '-z', '--stdin',
             'export-subst', 'export-ignore'],
            cwd=ROOT, env=env, input=request,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        if process.returncode != 0:
            raise ValueError('No se pudieron comprobar los atributos de exportación')
    fields = process.stdout.split(b'\0')
    if fields and fields[-1] == b'':
        fields.pop()
    if len(fields) % 3:
        raise ValueError('No se pudieron comprobar los atributos de exportación')
    for index in range(0, len(fields), 3):
        name = fields[index].decode('utf-8', 'replace')
        attribute = fields[index + 1].decode('ascii', 'replace')
        value = fields[index + 2].decode('ascii', 'replace')
        if value == 'set':
            raise ValueError(
                f'El commit activa {attribute} en {name}: el archivo no sería el revisado'
            )


def read_blobs(commit, names):
    """The bytes of every blob of the commit, read in one batch."""
    request = b''.join(f'{commit}:{name}\n'.encode('utf-8') for name in names)
    process = subprocess.run(
        ['git', 'cat-file', '--batch'], cwd=ROOT, env=GIT_ENV, input=request,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if process.returncode != 0:
        raise ValueError('No se pudieron leer los blobs del commit')
    data = process.stdout
    blobs = {}
    offset = 0
    for name in names:
        end = data.find(b'\n', offset)
        if end < 0:
            raise ValueError(f'No se pudo leer el blob de {name}')
        header = data[offset:end].split(b' ')
        if len(header) != 3 or header[1] != b'blob':
            raise ValueError(f'No se pudo leer el blob de {name}')
        try:
            size = int(header[2])
        except ValueError:
            raise ValueError(f'No se pudo leer el blob de {name}')
        start = end + 1
        blobs[name] = data[start:start + size]
        offset = start + size + 1
    return blobs


def archived_bytes(commit, name):
    """The bytes Git writes for a path: the blob with its `eol` conversion."""
    process = subprocess.run(
        ['git', 'cat-file', '--filters', f'{commit}:{name}'], cwd=ROOT, env=GIT_ENV,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if process.returncode != 0:
        raise ValueError(f'No se pudo leer el blob de {name}')
    return process.stdout


def only_line_endings(first, second):
    """True when two byte strings differ only in the line endings."""
    return first.replace(b'\r\n', b'\n') == second.replace(b'\r\n', b'\n')


def verify_committed_bytes(commit, destination, names):
    """The exported bytes must be the bytes of the committed blob.

    `git archive` applies the `eol` attribute of the path, so the archived
    file can differ from the blob in the line endings; that difference, and
    only that one, is allowed. Any other rewrite, such as the substitution
    of `export-subst`, is refused.
    """
    blobs = read_blobs(commit, names)
    for name in names:
        exported = destination / name
        if not exported.is_file():
            raise ValueError(f'El fichero exportado no existe: {name}')
        data = exported.read_bytes()
        blob = blobs[name]
        if data == blob:
            continue
        expected = archived_bytes(commit, name)
        if data != expected or not only_line_endings(expected, blob):
            raise ValueError(
                f'Los bytes exportados no son los del commit: {name}'
            )


def select_files(commit):
    patterns = [line.strip() for line in (HERE / 'allowlist.txt').read_text(
        encoding='utf-8').splitlines() if line.strip() and not line.startswith('#')]
    if not patterns or any(not safe_name(p) for p in patterns):
        raise ValueError('Lista permitida vacía o con patrones no válidos')
    tree = git('ls-tree', '-rz', '--full-tree', commit)
    selected = {}
    for record in tree.split(b'\0'):
        if not record:
            continue
        metadata, raw_name = record.split(b'\t', 1)
        mode, kind, _oid = metadata.split()
        name = raw_name.decode('utf-8')
        if not any(fnmatch.fnmatchcase(name, p) for p in patterns):
            continue
        if not safe_name(name) or forbidden(name):
            raise ValueError(f'Ruta prohibida en la selección: {name}')
        if kind != b'blob' or mode not in {b'100644', b'100755'}:
            raise ValueError(f'Enlace simbólico, submódulo o modo no permitido: {name}')
        selected[name] = mode
    if 'app/pubspec.yaml' not in selected or not selected:
        raise ValueError('El commit no contiene una selección válida de Cuadrante')
    check_export_attributes(commit, sorted(selected))
    return selected


def extract(commit, destination, selected):
    # Stream the committed archive; never copy the worktree or extract unlisted paths.
    # Use a file for stderr to avoid a full pipe deadlocking the archive stream.
    with tempfile.TemporaryFile() as errors:
        process = subprocess.Popen(
            ['git', 'archive', '--format=tar', commit], cwd=ROOT,
            env=GIT_ENV, stdout=subprocess.PIPE, stderr=errors,
        )
        seen = set()
        try:
            with tarfile.open(fileobj=process.stdout, mode='r|') as archive:
                for member in archive:
                    name = member.name
                    if name not in selected:
                        continue
                    if not safe_name(name) or not member.isfile() or name in seen:
                        raise ValueError(f'Entrada de archivo no válida: {name}')
                    data = archive.extractfile(member).read()
                    scan_file(name, data)
                    target = destination / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(data)
                    target.chmod(0o755 if selected[name] == b'100755' else 0o644)
                    seen.add(name)
            # `git archive` pads the tar with the rest of the record and the
            # reader stops at the end of the archive: drain what is left, or
            # the process waits forever for a pipe that nobody reads.
            while process.stdout.read(65536):
                pass
            if process.wait() != 0:
                raise ValueError('git archive no ha terminado correctamente')
        finally:
            process.stdout.close()
            if process.poll() is None:
                process.terminate()
            process.wait()
    if seen != set(selected):
        raise ValueError('git archive omitió ficheros permitidos (revisar export-ignore)')
    # Read back the exact exported bytes before creating any Git metadata.
    for name in sorted(seen):
        scan_file(name, (destination / name).read_bytes())
    # The archived bytes must be the bytes of the committed blob.
    verify_committed_bytes(commit, destination, sorted(seen))
    return len(seen)


def export(revision, target):
    commit = git('rev-parse', '--verify', '--end-of-options', revision + '^{commit}').decode().strip()
    # The private identity is read at runtime, never stored in this file.
    load_private_emails()
    destination = Path(target).absolute()
    # Reject symlink destinations/ancestors and exports into the source repository.
    if any(p.is_symlink() for p in (destination, *destination.parents)):
        raise ValueError('El destino o uno de sus padres es un enlace simbólico')
    destination = destination.resolve()
    if destination == ROOT or ROOT in destination.parents:
        raise ValueError('El destino debe estar fuera del repositorio de origen')
    existed = destination.exists()
    if existed and (not destination.is_dir() or any(destination.iterdir())):
        raise ValueError('El destino ya existe y no está vacío')
    selected = select_files(commit)
    author_name = os.environ.get('PUBLIC_AUTHOR_NAME', 'Daniel Mont Ferrandiz')
    author_email = os.environ.get('PUBLIC_AUTHOR_EMAIL', 'dev@mainshai.com')
    for value in (author_name, author_email):
        if not value.strip() or re.search(r'[<>\x00-\x1f\x7f]', value):
            raise ValueError('Identidad pública vacía o no válida')
        scan_bytes('identidad pública', value.encode('utf-8'))
    destination.mkdir(parents=True, exist_ok=True)
    # Build in a sibling staging directory; on failure leave the destination empty.
    # TemporaryDirectory only removes the staging directory owned by this invocation.
    with tempfile.TemporaryDirectory(prefix='.cuadrante-export-', dir=destination.parent) as temporary:
        staging = Path(temporary)
        count = extract(commit, staging, selected)
        git('init', '--quiet', '--initial-branch=main', '--template=', str(staging))
        identity = dict(GIT_ENV, GIT_AUTHOR_NAME=author_name, GIT_AUTHOR_EMAIL=author_email,
                        GIT_COMMITTER_NAME=author_name, GIT_COMMITTER_EMAIL=author_email)
        git('add', '--force', '--all', cwd=staging)
        # Preserve executable bits even on Windows filesystems with core.filemode=false.
        executable = [n for n, mode in selected.items() if mode == b'100755']
        for name in executable:
            git('update-index', '--chmod=+x', '--', name, cwd=staging)
        git('-c', 'commit.gpgSign=false', 'commit', '--quiet', '--no-verify',
            '-m', 'Initial public release of Cuadrante', cwd=staging, env=identity)
        if git('rev-list', '--count', 'HEAD', cwd=staging).strip() != b'1':
            raise ValueError('El destino no tiene exactamente un commit')
        if git('remote', cwd=staging).strip():
            raise ValueError('El destino tiene remotos')
        tracked = set(git('ls-files', '-z', cwd=staging).decode().rstrip('\0').split('\0'))
        if tracked != set(selected):
            raise ValueError('El commit inicial no coincide con la selección')
        if git('status', '--porcelain', '--untracked-files=all', cwd=staging).strip():
            raise ValueError('La copia exportada tiene cambios sin confirmar')
        if any(destination.iterdir()):
            raise ValueError('El destino dejó de estar vacío durante la exportación')
        for child in staging.iterdir():
            child.rename(destination / child.name)
    print(f'OK: {count} ficheros; rutas, secretos, prohibidos y binarios comprobados.')
    print('OK: un commit inicial, identidad pública, sin remotos, árbol limpio.')
    print(f'Origen: {commit}')
    print(f'Destino: {destination}')


if __name__ == '__main__':
    try:
        if len(sys.argv) != 3:
            raise ValueError('Uso: export_public.sh <commit> <carpeta-destino>')
        export(sys.argv[1], sys.argv[2])
    except (ValueError, OSError, EOFError, subprocess.SubprocessError,
            tarfile.TarError, zipfile.BadZipFile) as error:
        # Git stderr can contain sensitive source content: do not echo it.
        print(f'ERROR: {error if not isinstance(error, subprocess.SubprocessError) else "operación Git fallida"}', file=sys.stderr)
        sys.exit(1)
