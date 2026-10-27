"""Regression tests. All repositories and output live in temporary directories."""

import gzip
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('exporter', HERE / 'export_public.py')
exporter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(exporter)


class ScannerTest(unittest.TestCase):
    def test_personal_paths_and_identifiers(self):
        for value in [b'Z:/' + b'Users/example', b'C:' + b'\\Users\\example',
                      b'/' + b'Users/example', b'df' + b'err']:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    exporter.scan_file('app/lib/a.dart', value)

    def test_public_github_account_is_allowed(self):
        exporter.scan_file('README.md', b'https://github.com/df' + b'errandizmont/cuadrante')
        exporter.scan_file('README.md', b'https://github.com/df' + b'errandizmont/cuadrante.git')
        exporter.scan_file('README.md', b'@' + b'df' + b'errandizmont')
        exporter.scan_file('README.md', b'public@example.org')

    def test_gmail_addresses_are_rejected(self):
        # The literals are split: the exporter scans this very file too.
        for value in [b'yo@' + b'gmail.com', b'YO@' + b'GMAIL.COM',
                      b'nombre.apellido@' + b'gmail.com']:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    exporter.scan_file('app/lib/a.dart', value)
        exporter.scan_file('app/lib/a.dart', b'yo@example.com')

    def test_gmail_domain_boundary(self):
        # A domain that only begins with "gmail.com" is not a Gmail mailbox.
        exporter.scan_file('app/lib/a.dart', b'person@' + b'gmail.com.example.org')
        exporter.scan_file('app/lib/a.dart', b'person@' + b'gmail.community')
        # A real mailbox is refused, also with a trailing dot or comma.
        for value in [b'person@' + b'gmail.com', b'person@' + b'gmail.com.',
                      b'person@' + b'gmail.com,']:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    exporter.scan_file('app/lib/a.dart', value)

    def test_private_repository_email_is_rejected(self):
        # The email is read at runtime: the test provides its own value.
        saved = set(exporter.PRIVATE_EMAILS)
        original = exporter.read_config_email
        exporter.read_config_email = lambda: 'Privado@Example.ORG'
        try:
            exporter.load_private_emails()
            with self.assertRaises(ValueError):
                exporter.scan_file('README.md', b'contacto: privado@example.org')
            exporter.scan_file('README.md', b'contacto: public@example.org')
        finally:
            exporter.read_config_email = original
            exporter.PRIVATE_EMAILS.clear()
            exporter.PRIVATE_EMAILS.update(saved)

    def test_secrets_and_private_names(self):
        for value in [b'ghp' + b'_' + b'a' * 36, b'sk' + b'-' + b'a' * 32,
                      b'AK' + b'IA' + b'A' * 16,
                      b'-----BEGIN ' + b'RSA PRIVATE KEY-----']:
            with self.assertRaises(ValueError):
                exporter.scan_file('app/lib/a.dart', value)
        for name in ['.env', 'app/.env.dev', 'app/key.properties',
                     'app/signing.jks', 'app/key.keystore', 'app/release.apk',
                     'CLAUDE.md', 'docs/handoff.md', 'docs/qa-hallazgos/T01.md']:
            with self.subTest(name=name):
                with self.assertRaises(ValueError):
                    exporter.scan_file(name, b'innocent')

    def test_new_secret_patterns_are_rejected(self):
        # The literals are split: the exporter scans this very file too.
        for value in [b'AIza' + b'0' * 35, b'sk' + b'_live_' + b'a' * 24,
                      b'xox' + b'b-1234-5678-abcdef', b'appl' + b'_' + b'A' * 24,
                      b'goog' + b'_' + b'a' * 24,
                      b'eyJhbGciOiJIUzI1NiJ9' + b'.' + b'eyJzdWIiOiIxIn0' + b'.abc',
                      b'storePassword' + b' = hunter2', b'keyPassword' + b'=hunter2']:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    exporter.scan_file('app/lib/a.dart', value)

    def test_password_assignments_in_json_gradle_and_groovy(self):
        # The literals are split: the exporter scans this very file too.
        for value in [b'{"store' + b'Password": "synthetic"}',
                      b'{"key' + b'Password":"synthetic"}',
                      b'key' + b"Password 'synthetic'",
                      b'key' + b'Password = "synthetic"',
                      b'store' + b'Password=synthetic',
                      b'store' + b'Password: synthetic',
                      b'key' + b'Password("synthetic")']:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    exporter.scan_file('app/lib/a.dart', value)
        # The name of the field on its own is not a password.
        exporter.scan_file('app/lib/a.dart', b'el campo store' + b'Password se guarda cifrado')
        exporter.scan_file('app/lib/a.dart', b'`store' + b'Password` y `key' + b'Password`')
        # Reading it from the gitignored key.properties is not a password either.
        exporter.scan_file('app/android/app/build.gradle.kts',
                           b'store' + b'Password = keyProperties.getProperty("store' + b'Password")')
        with self.assertRaises(ValueError):
            exporter.scan_file('app/android/app/build.gradle.kts',
                               b'store' + b'Password = keyProperties.getProperty("x") ?: "synthetic"')

    def test_jwt_variants_are_rejected(self):
        # The literals are split: the exporter scans this very file too.
        for value in [b'eyJ' + b'hbGciOiJIUzI1NiJ9.e30.sig',
                      b'eyJ' + b'hbGciOiJIUzI1NiJ9.e30.',
                      b'eyJ' + b'hbGciOiJIUzI1NiJ9.e30']:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    exporter.scan_file('app/lib/a.dart', value)
        # A dotted name or a bare fragment is not a token.
        exporter.scan_file('app/lib/a.dart', b'com.example.cuadrante')
        exporter.scan_file('app/lib/a.dart', b'eyJ')

    def test_forbidden_names_and_extensions(self):
        for name in ['app/keystore.p8', 'app/certificate.p12', 'app/private.pem',
                     'app/private.key', 'app/app.mobileprovision',
                     'app/google-services.json', 'app/GoogleService-Info.plist',
                     'app/local.properties', 'app/production.env',
                     'app/secrets.json', 'app/secrets.yaml']:
            with self.subTest(name=name):
                with self.assertRaises(ValueError):
                    exporter.scan_file(name, b'innocent')
        exporter.scan_file('app/lib/config.dart', b'innocent')

    def test_binary_locations_and_compressed_fixture(self):
        exporter.scan_file('app/assets/icon/icon.png', b'\x89PNG\x00')
        exporter.scan_file('app/test/fixtures/v1.cuadrante', gzip.compress(b'{"synthetic":true}'))
        with self.assertRaises(ValueError):
            exporter.scan_file('tool/program.jar', b'PK\x00')
        with self.assertRaises(ValueError):
            exporter.scan_file('app/test/fixtures/v1.cuadrante', gzip.compress(b'ghp' + b'_' + b'a' * 36))


class ExportTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='cuadrante-publish-test-')
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.source = self.base / 'source with spaces'
        (self.source / 'tool/publish').mkdir(parents=True)
        for name in ['export_public.sh', 'export_public.py']:
            shutil.copyfile(HERE / name, self.source / 'tool/publish' / name)
        self.policy = self.source / 'tool/publish/allowlist.txt'
        self.policy.write_text('app/*\nREADME.md\n.gitattributes\n', encoding='utf-8')
        (self.source / 'app').mkdir()
        (self.source / 'app/pubspec.yaml').write_text('name: fixture\n', encoding='utf-8')
        (self.source / 'README.md').write_text('Public text\n', encoding='utf-8')
        (self.source / 'private.md').write_text('Excluded research\n', encoding='utf-8')
        self.env = dict(exporter.GIT_ENV, GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.org',
                        GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.org',
                        PUBLIC_AUTHOR_NAME='Public Author', PUBLIC_AUTHOR_EMAIL='public@example.org')
        self.git('init', '--quiet', '--initial-branch=main', '--template=')
        # The exporter reads the author email from Git at runtime: fix it here.
        self.git('config', 'user.email', 'autor@example.org')
        self.commit()
        self.destination = self.base / 'public with spaces'

    def git(self, *args, cwd=None):
        return subprocess.check_output(['git', *args], cwd=cwd or self.source,
                                       env=self.env, stderr=subprocess.PIPE)

    def commit(self):
        self.git('add', '--all')
        self.git('-c', 'commit.gpgSign=false', 'commit', '--quiet', '-m', 'Private development')

    def run_export(self, revision='HEAD', shell=False):
        entry = self.source / 'tool/publish' / ('export_public.sh' if shell else 'export_public.py')
        command = ['sh'] if shell else [sys.executable, '-B']
        return subprocess.run([*command, str(entry), revision, str(self.destination)],
                              env=dict(self.env, PUBLIC_PYTHON=sys.executable), capture_output=True)

    def test_committed_bytes_only_single_commit_no_remote(self):
        (self.source / 'README.md').write_text('Uncommitted private text', encoding='utf-8')
        result = self.run_export(shell=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.destination / 'README.md').read_text(), 'Public text\n')
        self.assertFalse((self.destination / 'private.md').exists())
        self.assertEqual(self.git('rev-list', '--count', 'HEAD', cwd=self.destination).strip(), b'1')
        self.assertEqual(self.git('remote', cwd=self.destination), b'')
        self.assertEqual(self.git('show', '-s', '--format=%an <%ae>|%cn <%ce>', cwd=self.destination).strip(),
                         b'Public Author <public@example.org>|Public Author <public@example.org>')
        self.assertEqual(self.git('status', '--porcelain', cwd=self.destination), b'')

    def test_nonempty_destination_is_untouched(self):
        self.destination.mkdir()
        marker = self.destination / '.hidden'
        marker.write_text('keep', encoding='utf-8')
        result = self.run_export()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.destination.iterdir()), [marker])
        self.assertEqual(marker.read_text(), 'keep')

    def test_default_identity_title_and_existing_empty_destination(self):
        self.env.pop('PUBLIC_AUTHOR_NAME')
        self.env.pop('PUBLIC_AUTHOR_EMAIL')
        self.destination.mkdir()
        result = self.run_export()
        self.assertEqual(result.returncode, 0, result.stderr)
        identity = self.git('show', '-s', '--format=%an <%ae>|%cn <%ce>|%s', cwd=self.destination)
        self.assertEqual(identity.decode('utf-8').strip(),
                         'Daniel Mont Ferrandiz <dev@mainshai.com>|'
                         'Daniel Mont Ferrandiz <dev@mainshai.com>|Initial public release of Cuadrante')

    def test_failure_leaves_empty_destination(self):
        (self.source / 'app/leak.dart').write_text('sk' + '-' + 'a' * 32, encoding='utf-8')
        self.commit()
        result = self.run_export()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(b'a' * 32, result.stderr)
        self.assertEqual(list(self.destination.iterdir()), [])

    def test_no_old_history_is_inherited(self):
        (self.source / 'README.md').write_text('Second version\n', encoding='utf-8')
        self.commit()
        result = self.run_export()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('rev-list', '--count', 'HEAD', cwd=self.source).strip(), b'2')
        self.assertEqual(self.git('rev-list', '--count', '--all', cwd=self.destination).strip(), b'1')

    def test_the_author_email_is_read_from_git_at_runtime(self):
        # The exporter takes the email from the repository, never from the code.
        (self.source / 'app/contacto.dart').write_text(
            'const correo = "autor@example.org";\n', encoding='utf-8')
        self.commit()
        result = self.run_export()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.destination.iterdir()), [])

    def test_export_attributes_are_rejected(self):
        # Only an attribute that is active on an exported file is refused.
        for attribute in ['export-subst', 'export-ignore']:
            with self.subTest(attribute=attribute):
                (self.source / '.gitattributes').write_text(
                    f'app/pubspec.yaml {attribute}\n', encoding='utf-8')
                self.commit()
                result = self.run_export()
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.destination.exists())
                (self.source / '.gitattributes').unlink()
                self.commit()

    def test_disabled_and_commented_export_attributes_are_allowed(self):
        # A disabled attribute and a commented line change nothing.
        for index, line in enumerate(['app/pubspec.yaml -export-ignore\n',
                                      '# app/pubspec.yaml export-ignore\n',
                                      '*.dart export-subst\n']):
            with self.subTest(line=line):
                (self.source / '.gitattributes').write_text(line, encoding='utf-8')
                self.commit()
                # A new destination for every case: the exported one is a
                # repository with read-only objects.
                self.destination = self.base / f'public {index}'
                result = self.run_export()
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_repository_attributes_are_applied(self):
        # `$GIT_DIR/info/attributes` is not versioned, but Git applies it.
        info = self.source / '.git' / 'info'
        info.mkdir(parents=True, exist_ok=True)
        (info / 'attributes').write_text(
            'app/pubspec.yaml export-subst\n', encoding='utf-8')
        result = self.run_export()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.destination.exists())

    def test_exported_bytes_are_the_bytes_of_the_commit(self):
        result = self.run_export()
        self.assertEqual(result.returncode, 0, result.stderr)
        commit = self.git('rev-parse', 'HEAD').decode().strip()
        saved = exporter.ROOT
        exporter.ROOT = self.source
        try:
            exporter.verify_committed_bytes(commit, self.destination, ['README.md'])
            # A copy that does not match the blob is refused.
            (self.destination / 'README.md').write_text('Changed\n', encoding='utf-8')
            with self.assertRaises(ValueError):
                exporter.verify_committed_bytes(commit, self.destination, ['README.md'])
        finally:
            exporter.ROOT = saved

    def test_line_ending_conversion_is_allowed(self):
        # `git archive` converts the line endings of a batch file: the exported
        # bytes differ from the blob and that difference is allowed.
        (self.source / '.gitattributes').write_text(
            '*.bat text eol=crlf\n', encoding='utf-8')
        (self.source / 'app' / 'run.bat').write_text('echo hola\n', encoding='utf-8')
        self.commit()
        result = self.run_export()
        self.assertEqual(result.returncode, 0, result.stderr)
        exported = (self.destination / 'app' / 'run.bat').read_bytes()
        self.assertIn(b'\r\n', exported)
        self.assertNotEqual(exported, self.git('cat-file', 'blob', 'HEAD:app/run.bat'))

    def test_symlink_mode_is_rejected_before_archive(self):
        # Build a Git symlink without requiring Windows symlink privileges.
        process = subprocess.run(['git', 'hash-object', '-w', '--stdin'], input=b'../private.md',
                                 cwd=self.source, env=self.env, capture_output=True, check=True)
        self.git('update-index', '--add', '--cacheinfo', '120000', process.stdout.decode().strip(), 'app/link')
        self.git('-c', 'commit.gpgSign=false', 'commit', '--quiet', '-m', 'Link')
        result = self.run_export()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.destination.exists())

    def test_invalid_revision_and_source_destination(self):
        self.assertNotEqual(self.run_export('--all').returncode, 0)
        self.destination = self.source / 'export'
        self.assertNotEqual(self.run_export().returncode, 0)


if __name__ == '__main__':
    unittest.main()
