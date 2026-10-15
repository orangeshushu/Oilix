"""Regression checks that do not initialize a database or load model weights."""
import ast
import json
from pathlib import Path
import runpy
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch


SERVER = Path(__file__).resolve().parents[1]


class HistoryDeliveryTests(unittest.TestCase):
    def test_static_root_does_not_follow_service_wrapper(self):
        for entrypoint in (str(SERVER / 'main.py'), '/usr/local/lib/wateroil/serve_local.py'):
            with self.subTest(entrypoint=entrypoint), patch('sys.argv', [entrypoint]):
                config = runpy.run_path(str(SERVER / 'settings/configs.py'))
                self.assertEqual(config['settings']['static_path'], str(SERVER / 'static'))
                self.assertEqual(config['settings']['template_path'], str(SERVER / 'templates'))
                self.assertTrue((Path(config['settings']['static_path']) / 'console/index.html').is_file())

    def handler_class(self):
        # Execute the actual handler with a fake base, avoiding package startup side effects.
        tree = ast.parse((SERVER / 'handlers/admin.py').read_text())
        handler = next(node for node in tree.body if isinstance(node, ast.ClassDef)
                       and node.name == 'AdminPhotoListHandler')
        namespace = {'BaseHandler': object, 'json': json,
                     'info': {'status': 0, 'msg': {'old': 'private record'}, 'meta': {}}}
        exec(compile(ast.Module(body=[handler], type_ignores=[]), 'admin.py', 'exec'), namespace)
        return namespace['AdminPhotoListHandler']

    def test_regular_user_cannot_read_admin_samples(self):
        handler = self.handler_class()()
        handler.getAccount = Mock(return_value=SimpleNamespace(role=0))
        handler.set_status = Mock()
        handler.write = Mock()
        handler.post()
        handler.set_status.assert_called_once_with(403)
        body = json.loads(handler.write.call_args.args[0])
        self.assertEqual(body['status'], 7)
        self.assertEqual(body['meta'], {})
        self.assertNotIn('private record', handler.write.call_args.args[0])

    def test_signed_out_user_receives_no_records(self):
        handler = self.handler_class()()
        handler.getAccount = Mock(return_value=None)
        handler.saveLog = Mock()
        handler.write = Mock()
        handler.post()
        body = json.loads(handler.write.call_args.args[0])
        self.assertEqual(body['status'], 8)
        self.assertEqual(body['msg'], 'Login timeout.')


if __name__ == '__main__':
    unittest.main()
