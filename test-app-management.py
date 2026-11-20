"""Exercise menu choices and update behavior with fake installers, never real apps."""
import json
import os
import pathlib
import plistlib
import shutil
import subprocess
import tempfile
import unittest
import sys
from unittest import mock
import contextlib
import io
import runpy

ROOT = pathlib.Path(__file__).resolve().parent


class AppManagementTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-tests-")
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "calls"
        self.env = dict(os.environ, PATH=str(self.bin) + ":/usr/bin:/bin", TEST_LOG=str(self.log),
                        DOTFILES_ASSUME_YES="1", HOME=str(self.root / "home"))
        pathlib.Path(self.env["HOME"]).mkdir()
        self.env.pop("DOTFILES_INSTALL_ALL", None)
        # Isolate filesystem detection from real applications on this Mac.
        (self.root / "app-installed.py").write_text("import sys; sys.exit(1)\n")
        for name in ["office-installer.sh", "menu-ui.sh", "Brewfile.office", "Brewfile.office.mas", "update.sh"]:
            shutil.copy2(ROOT / name, self.root / name)
        self.stub("uname", 'echo Darwin')
        self.stub("caffeinate", 'shift; exec "$@"')
        self.stub("brew", '''printf 'brew %s\\n' "$*" >> "$TEST_LOG"
case "$*" in
  'list --formula '*|'list --cask '*) exit 1 ;;
  'outdated --formula --verbose') echo 'unlisted-tool (1) < 2' ;;
  'outdated --cask --greedy --verbose') echo 'unlisted-app (1) < 2' ;;
  '--prefix unlisted-tool') echo /nonexistent-test-prefix ;;
esac
[[ "$*" != *"${FAIL_CASK:-never-match}"* ]]''')
        self.stub("mas", '''printf 'mas %s\\n' "$*" >> "$TEST_LOG"
if [[ "$1" == outdated ]]; then echo '462058435 Microsoft Excel (1 -> 2)'; fi''')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)

    def run_script(self, name, answer="", **extra):
        return subprocess.run(["/bin/bash", str(self.root / name)], input=answer, text=True,
                              capture_output=True, env=dict(self.env, **extra))

    def calls(self):
        return self.log.read_text() if self.log.exists() else ""

    def test_work_apps_can_be_selected_individually(self):
        result = self.run_script("office-installer.sh", "2 7\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("mas install 985367838", self.calls())
        self.assertIn("brew install --cask --appdir=/Applications displaylink", self.calls())
        self.assertNotIn("microsoft-teams", self.calls())

    def test_setup_opens_menu_without_installing_missing_core_apps(self):
        shutil.copy2(ROOT / "setup.sh", self.root / "setup.sh")
        # Even a machine with no installed core packages must open the menu.
        self.stub("brew", '''printf 'brew %s\\n' "$*" >> "$TEST_LOG"
if [[ "$1" == shellenv ]]; then exit 0; fi
exit 1''')
        (self.root / "bootstrap.sh").write_text('#!/bin/bash\necho UNEXPECTED_INSTALL\nexit 99\n')
        (self.root / "bootstrap.sh").chmod(0o755)
        result = self.run_script("setup.sh", "q\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("macOS manager", result.stdout)
        self.assertNotIn("UNEXPECTED_INSTALL", result.stdout)
        for action in ["bundle", "install", "upgrade", "update"]:
            self.assertNotIn(action, self.calls())

    def test_install_all_work_apps_excludes_iwork_and_vmware(self):
        result = self.run_script("office-installer.sh", DOTFILES_INSTALL_ALL="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls().count("mas install"), 5)
        self.assertEqual(self.calls().count("brew install --cask"), 6)
        for app in ["microsoft-teams", "displaylink", "citrix-workspace", "okta-verify"]:
            self.assertIn(app, self.calls())
        self.assertNotIn("vmware", self.calls())
        self.assertNotIn("361304891", self.calls())

    def test_invalid_work_selection_does_not_install(self):
        result = self.run_script("office-installer.sh", "011\n")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.calls(), "")

    def test_quit_keeps_global_quit_status(self):
        result = self.run_script("office-installer.sh", "q\n")
        self.assertEqual(result.returncode, 21)

    def test_failure_does_not_skip_other_selected_apps(self):
        result = self.run_script("office-installer.sh", "7 9\n", FAIL_CASK="displaylink")
        self.assertEqual(result.returncode, 1)
        self.assertIn("okta-verify", self.calls())

    def test_updates_include_packages_outside_the_brewfiles(self):
        result = self.run_script("update.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("brew upgrade --formula unlisted-tool", self.calls())
        self.assertIn("brew upgrade --cask --greedy unlisted-app", self.calls())
        self.assertIn("mas upgrade 462058435", self.calls())

    def test_profile_parsing_works_with_macos_sed(self):
        profile = self.root / "profile"
        profile.write_text('brew "some-tool"\ncask "some-app"\nmas "Example", id: 123\n')
        result = subprocess.run(["/bin/bash", "-c", 'set -euo pipefail; source "$1/menu-ui.sh"; '
                                 'install_brewfile_items "$1/profile"; install_mas_items "$1/profile"',
                                 "test", str(self.root)], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("brew install some-tool", self.calls())
        self.assertIn("brew install --cask --appdir=/Applications some-app", self.calls())
        self.assertIn("mas install 123", self.calls())

    def test_audit_counts_optional_profiles_and_excludes_dependencies(self):
        prefix = self.root / "brew-prefix"
        for name, on_request in [("extra-tool", True), ("dependency", False)]:
            receipt = prefix / "Cellar" / name / "1" / "INSTALL_RECEIPT.json"
            receipt.parent.mkdir(parents=True)
            receipt.write_text(json.dumps({"installed_on_request": on_request}))
        for name in ["okta-verify", "extra-app"]:
            receipt = prefix / "Caskroom" / name / ".metadata" / "INSTALL_RECEIPT.json"
            receipt.parent.mkdir(parents=True)
            receipt.write_text(json.dumps({"uninstall_artifacts": []}))
        shutil.copy2(ROOT / "system-apps.conf", self.root / "system-apps.conf")
        result = subprocess.run(["/usr/bin/python3", str(ROOT / "audit-apps.py"), str(self.root), str(prefix)],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("  - extra-app", result.stdout)
        self.assertIn("  - extra-tool", result.stdout)
        self.assertNotIn("  - dependency", result.stdout)
        self.assertNotIn("  - okta-verify", result.stdout)

    def test_migration_dry_run_preserves_apps_and_brew_receipts(self):
        shutil.copy2(ROOT / "migrate-apps.sh", self.root / "migrate-apps.sh")
        caskroom = self.root / "Caskroom"
        metadata = caskroom / "example" / ".metadata"
        metadata.mkdir(parents=True)
        home_apps = pathlib.Path(self.env["HOME"]) / "Applications"
        (home_apps / "Unique Migration Test.app").mkdir(parents=True)
        config = metadata / "config.json"
        config.write_text(json.dumps({"env": {"appdir": str(home_apps)}}))
        (metadata / "INSTALL_RECEIPT.json").write_text(json.dumps({
            "uninstall_artifacts": [{"app": ["Unique Migration Test.app"]}]}))
        self.stub("brew", '[[ "$1" == --caskroom ]] && echo "$TEST_CASKROOM"')
        original = config.read_bytes()
        result = subprocess.run(["/bin/bash", str(self.root / "migrate-apps.sh"), "--dry-run"],
                                text=True, capture_output=True, env=dict(self.env, TEST_CASKROOM=str(caskroom)))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("cask|example|", result.stdout)
        self.assertTrue((home_apps / "Unique Migration Test.app").exists())
        self.assertEqual(config.read_bytes(), original)

    def audit_manage(self, answers):
        prefix = self.root / "audit-prefix"
        cask = prefix / "Caskroom" / "extra-app" / ".metadata" / "INSTALL_RECEIPT.json"
        cask.parent.mkdir(parents=True, exist_ok=True)
        cask.write_text(json.dumps({"uninstall_artifacts": []}))
        formula = prefix / "Cellar" / "borders" / "1" / "INSTALL_RECEIPT.json"
        formula.parent.mkdir(parents=True, exist_ok=True)
        formula.write_text(json.dumps({"installed_on_request": True}))
        shutil.copy2(ROOT / "system-apps.conf", self.root / "system-apps.conf")
        with mock.patch.object(sys, "argv", ["audit-apps.py", str(self.root), str(prefix), "--manage"]), \
                mock.patch("os.walk", return_value=[]), \
                mock.patch("builtins.input", side_effect=answers), \
                mock.patch("subprocess.run") as commands, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(SystemExit) as result:
                runpy.run_path(str(ROOT / "audit-apps.py"), run_name="__main__")
            return result.exception.code, commands.call_args_list

    def test_audit_removal_requires_confirmation(self):
        status, commands = self.audit_manage(["1", "n"])
        self.assertEqual(status, 20)
        self.assertEqual(commands, [])

    def test_audit_removes_only_selected_items_once_without_zap(self):
        status, commands = self.audit_manage(["1 1", "y"])
        self.assertEqual(status, 0)
        self.assertEqual(commands, [mock.call(["brew", "uninstall", "--cask", "extra-app"], check=True)])

    def test_audit_checks_all_choices_before_any_removal(self):
        status, commands = self.audit_manage(["1 99"])
        self.assertEqual(status, 1)
        self.assertEqual(commands, [])

    def test_audit_stops_selected_retired_service_before_uninstalling(self):
        status, commands = self.audit_manage(["2", "y"])
        self.assertEqual(status, 0)
        self.assertEqual(commands, [mock.call(["brew", "services", "stop", "borders"], check=True),
                                    mock.call(["brew", "uninstall", "--formula", "borders"], check=True)])

    def test_app_menu_no_longer_contains_one_time_cleanup(self):
        shutil.copy2(ROOT / "manage-apps.sh", self.root / "manage-apps.sh")
        result = self.run_script("manage-apps.sh", "b\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("Review / remove apps outside", result.stdout)
        self.assertNotIn("6)", result.stdout)

    def test_existing_packages_are_skipped_without_updates(self):
        self.stub("brew", 'printf "brew %s\\n" "$*" >> "$TEST_LOG"; exit 0')
        self.stub("mas", 'echo "123 Example (old-version)"')
        result = subprocess.run(["/bin/bash", "-c", 'set -euo pipefail; source "$1/menu-ui.sh"; '
                                 'install_formula existing-tool; install_cask existing-app; install_mas_app 123 Example',
                                 "test", str(self.root)], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("brew install", self.calls())
        self.assertNotIn("upgrade", self.calls())
        self.assertEqual(result.stdout.count("skipped"), 3)

    def test_manually_installed_app_is_detected_in_home_folder(self):
        apps = self.root / "apps"
        (apps / "Pages Creator Studio.app").mkdir(parents=True)
        (apps / "Tailscale.app").mkdir()
        for name in ["Pages", "tailscale-app"]:
            result = subprocess.run(["/usr/bin/python3", str(ROOT / "app-installed.py"), name, str(apps)])
            self.assertEqual(result.returncode, 0)

    def test_current_codex_desktop_is_distinguished_from_classic(self):
        for bundle_id, expected in [("com.openai.chat", 1), ("com.openai.codex", 0)]:
            root = self.root / bundle_id
            contents = root / "ChatGPT.app" / "Contents"
            contents.mkdir(parents=True)
            (contents / "Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": bundle_id}))
            result = subprocess.run(["/usr/bin/python3", str(ROOT / "app-installed.py"), "chatgpt", str(root)])
            self.assertEqual(result.returncode, expected)

    def prepare_package_installation(self):
        for name in ["install-apps.sh", "system-apps.conf", "install-mac-apps.sh", "Brewfile.mas", "Brewfile.daily"]:
            shutil.copy2(ROOT / name, self.root / name)
        (self.root / "Brewfile").write_text('cask "standard-core"\n')
        (self.root / "Brewfile.personal").write_text('cask "standard-personal"\n')
        (self.root / "Brewfile.personal.mas").write_text('mas "Personal App", id: 456\n')
        (self.root / "Brewfile.dev").write_text('cask "development-only"\n')
        (self.root / "vendor-apps.sh").write_text('#!/bin/bash\nexit 0\n')
        (self.root / "vendor-apps.sh").chmod(0o755)

    def test_standard_install_excludes_work_and_development(self):
        self.prepare_package_installation()
        result = self.run_script("install-apps.sh", "1\n\nb\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("tailscale-app", self.calls())
        for excluded in ["development-only", "docker-desktop", "wacom-tablet", "citrix-workspace", "1362171212"]:
            self.assertNotIn(excluded, self.calls())
        self.assertNotIn("upgrade", self.calls())
        self.assertNotIn("  a)", result.stdout)
        self.assertNotIn("standard-personal", self.calls())
        self.assertNotIn("mas install 456", self.calls())

    def test_multiple_packages_install_together_with_one_confirmation(self):
        self.prepare_package_installation()
        self.env.pop("DOTFILES_ASSUME_YES")
        result = self.run_script("install-apps.sh", "1 3 4 3\ny\n\nb\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        for included in ["standard-core", "standard-personal", "development-only", "mas install 456"]:
            self.assertIn(included, self.calls())
        self.assertEqual(self.calls().count("brew install --cask --appdir=/Applications standard-personal"), 1)
        self.assertNotIn("docker-desktop", self.calls())

    def test_development_package_alone_does_not_require_a_store_profile(self):
        self.prepare_package_installation()
        result = self.run_script("install-apps.sh", "4\n\nb\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("development-only", self.calls())
        self.assertNotIn("mas install", self.calls())
        self.assertNotIn("tailscale-app", self.calls())

    def test_diagnostics_contains_audit_and_migration(self):
        shutil.copy2(ROOT / "diagnostics.sh", self.root / "diagnostics.sh")
        result = self.run_script("diagnostics.sh", "b\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Review / remove apps outside", result.stdout)
        self.assertIn("Move home-folder apps", result.stdout)

    def test_cleanup_backs_up_local_config_and_preserves_unrelated_files(self):
        shutil.copy2(ROOT / "cleanup-retired-apps.sh", self.root / "cleanup-retired-apps.sh")
        home = pathlib.Path(self.env["HOME"])
        config = home / ".config/aerospace"
        config.mkdir(parents=True)
        (config / "local-settings").write_text("personal settings")
        unrelated = home / ".config/unrelated"
        unrelated.write_text("keep me")
        self.stub("brew", "exit 1")  # No retired packages installed; never call real Homebrew.
        self.stub("pkill", "exit 1")
        self.stub("skhd", "exit 0")
        result = self.run_script("cleanup-retired-apps.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(config.exists())
        backups = list((home / ".local/share/dotfiles-backups").glob("retired.*/.config/aerospace/local-settings"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "personal settings")
        self.assertEqual(unrelated.read_text(), "keep me")


if __name__ == "__main__":
    unittest.main()
