#!/usr/bin/env python3
"""Unit tests for the litellm-local wrapper script."""

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add project root to path and import the wrapper as a module
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Read and exec the wrapper to get its functions
import types
litellm_local = types.ModuleType('litellm_local')
wrapper_path = str(PROJECT_ROOT / 'litellm-local')
litellm_local.__file__ = wrapper_path
litellm_local.__name__ = 'litellm_local'
with open(wrapper_path) as f:
    code = compile(f.read(), wrapper_path, 'exec')
exec(code, litellm_local.__dict__)


class TestArgParsing(unittest.TestCase):
    """Test argument parsing and subcommand dispatch."""

    def setUp(self):
        self.parser = litellm_local.build_parser()

    def test_start_command_registered(self):
        """Test that 'start' subcommand is registered."""
        args = self.parser.parse_args(['start'])
        self.assertEqual(args.command, 'start')

    def test_stop_command_registered(self):
        """Test that 'stop' subcommand is registered."""
        args = self.parser.parse_args(['stop'])
        self.assertEqual(args.command, 'stop')

    def test_status_command_registered(self):
        """Test that 'status' subcommand is registered."""
        args = self.parser.parse_args(['status'])
        self.assertEqual(args.command, 'status')

    def test_usage_command_registered(self):
        """Test that 'usage' subcommand is registered."""
        args = self.parser.parse_args(['usage'])
        self.assertEqual(args.command, 'usage')

    def test_webui_command_registered(self):
        """Test that 'webui' subcommand is registered."""
        args = self.parser.parse_args(['webui'])
        self.assertEqual(args.command, 'webui')

    def test_port_override(self):
        """Test that --port is passed through to subcommands."""
        args = self.parser.parse_args(['--port', '5000', 'start'])
        self.assertEqual(args.port, '5000')
        self.assertEqual(args.command, 'start')

    def test_webui_port_override(self):
        """Test that webui --port is separate from proxy port."""
        args = self.parser.parse_args(['webui', '--port', '9090'])
        self.assertEqual(args.port, '9090')
        self.assertEqual(args.command, 'webui')


class TestRunFunction(unittest.TestCase):
    """Test the run() helper function."""

    def setUp(self):
        self.subprocess_patcher = patch.object(litellm_local.subprocess, 'call')
        self.mock_call = self.subprocess_patcher.start()
        self.mock_call.return_value = 0

    def tearDown(self):
        self.subprocess_patcher.stop()

    def test_run_calls_subprocess(self):
        """Test that run() invokes subprocess.call with correct args."""
        result = litellm_local.run(['echo', 'hello'])
        self.mock_call.assert_called_once_with(['echo', 'hello'], cwd=litellm_local.SCRIPT_DIR)
        self.assertEqual(result, 0)

    def test_run_passes_kwargs(self):
        """Test that run() passes extra kwargs to subprocess.call."""
        env = {'TEST': '1'}
        litellm_local.run(['echo', 'hello'], env=env)
        self.mock_call.assert_called_once_with(['echo', 'hello'], cwd=litellm_local.SCRIPT_DIR, env=env)


class TestCommandHandlers(unittest.TestCase):
    """Test the command handler functions."""

    def setUp(self):
        self.mock_args = MagicMock()
        self.mock_args.port = None
        self.subprocess_patcher = patch.object(litellm_local.subprocess, 'call')
        self.mock_call = self.subprocess_patcher.start()
        self.mock_call.return_value = 0

    def tearDown(self):
        self.subprocess_patcher.stop()

    def test_cmd_start(self):
        """Test cmd_start calls start.sh."""
        result = litellm_local.cmd_start(self.mock_args)
        expected_cmd = [str(litellm_local.SCRIPT_DIR / 'start.sh')]
        self.mock_call.assert_called_once()
        args, _ = self.mock_call.call_args
        self.assertEqual(args[0], expected_cmd)
        self.assertEqual(result, 0)

    def test_cmd_stop(self):
        """Test cmd_stop calls stop.sh."""
        result = litellm_local.cmd_stop(self.mock_args)
        expected_cmd = [str(litellm_local.SCRIPT_DIR / 'stop.sh')]
        self.mock_call.assert_called_once()
        args, _ = self.mock_call.call_args
        self.assertEqual(args[0], expected_cmd)
        self.assertEqual(result, 0)

    def test_cmd_status(self):
        """Test cmd_status calls status.sh."""
        result = litellm_local.cmd_status(self.mock_args)
        expected_cmd = [str(litellm_local.SCRIPT_DIR / 'status.sh')]
        self.mock_call.assert_called_once()
        args, _ = self.mock_call.call_args
        self.assertEqual(args[0], expected_cmd)
        self.assertEqual(result, 0)

    def test_cmd_usage(self):
        """Test cmd_usage calls usage.sh."""
        result = litellm_local.cmd_usage(self.mock_args)
        expected_cmd = [str(litellm_local.SCRIPT_DIR / 'usage.sh')]
        self.mock_call.assert_called_once()
        args, _ = self.mock_call.call_args
        self.assertEqual(args[0], expected_cmd)
        self.assertEqual(result, 0)

    def test_cmd_webui(self):
        """Test cmd_webui calls webui.py."""
        result = litellm_local.cmd_webui(self.mock_args)
        self.mock_call.assert_called_once()
        args, kwargs = self.mock_call.call_args
        self.assertIn('webui.py', str(args[0]))
        self.assertEqual(result, 0)

    def test_cmd_start_with_port(self):
        """Test cmd_start passes PORT env var."""
        self.mock_args.port = '5000'
        litellm_local.cmd_start(self.mock_args)
        _, kwargs = self.mock_call.call_args
        self.assertEqual(kwargs['env']['PORT'], '5000')

    def test_cmd_webui_with_port(self):
        """Test cmd_webui passes WEBUI_PORT env var."""
        self.mock_args.port = '9090'
        litellm_local.cmd_webui(self.mock_args)
        _, kwargs = self.mock_call.call_args
        self.assertEqual(kwargs['env']['WEBUI_PORT'], '9090')

    def test_cmd_start_with_json_logs(self):
        """Test cmd_start passes LITELLM_JSON_LOGS env var when --json is set."""
        self.mock_args.json_logs = True
        litellm_local.cmd_start(self.mock_args)
        _, kwargs = self.mock_call.call_args
        self.assertEqual(kwargs['env']['LITELLM_JSON_LOGS'], 'true')

    def test_cmd_start_without_json_logs(self):
        """Test cmd_start does not set LITELLM_JSON_LOGS when --json is not set."""
        self.mock_args.json_logs = False
        litellm_local.cmd_start(self.mock_args)
        _, kwargs = self.mock_call.call_args
        self.assertNotIn('LITELLM_JSON_LOGS', kwargs['env'])


class TestPortEnvVar(unittest.TestCase):
    """Test PORT environment variable handling."""

    def _reload_module(self):
        """Re-exec the wrapper module to pick up env var changes."""
        new_mod = types.ModuleType('litellm_local')
        new_mod.__file__ = litellm_local.__file__
        new_mod.__name__ = 'litellm_local'
        with open(litellm_local.__file__) as f:
            code = compile(f.read(), litellm_local.__file__, 'exec')
        exec(code, new_mod.__dict__)
        return new_mod

    @patch.dict(os.environ, {}, clear=True)
    def test_port_default(self):
        """Test default PORT is 4000 when no env var set."""
        mod = self._reload_module()
        self.assertEqual(mod.PORT, '4000')

    @patch.dict(os.environ, {'PORT': '5000'})
    def test_port_from_env(self):
        """Test PORT is read from environment."""
        mod = self._reload_module()
        self.assertEqual(mod.PORT, '5000')


if __name__ == '__main__':
    unittest.main()
