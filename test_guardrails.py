"""Regresiones de guardrails: sin red, credenciales ni escrituras de producción."""
import json
import sys
import unittest
from contextlib import ExitStack
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, mock_open, patch

import extractor
import loader
import main as pipeline
import metadata
import reconciliar
from scripts import verificar_frescura as frescura

PROJECTS = {p: {'dataset_id': 'ds_' + p, 'env_prefix': 'ZOHO',
                'modules': {'A': ['Name'], 'B': ['Name']}}
            for p in ('colsubsidio', 'giz')}


class GuardrailsTest(unittest.TestCase):
    def test_load_attempts_all_projects_then_raises_and_audits(self):
        with patch.object(loader, 'PROJECTS', PROJECTS), patch.object(loader, 'get_client'), \
             patch.object(loader, 'ensure_metadata_table'), patch.object(loader, 'write_run') as audit, \
             patch.object(loader, 'load_module', side_effect=[ValueError('bad'), None, None, None]) as load:
            with self.assertRaisesRegex(RuntimeError, 'colsubsidio'):
                loader.run_load()
            self.assertEqual(load.call_count, 4)
            self.assertEqual(audit.call_args.args[3], 'error')
            self.assertEqual(audit.call_args.kwargs['dataset_id'], 'ds_colsubsidio')

    def test_load_success_for_each_project(self):
        for project in PROJECTS:
            with self.subTest(project=project), patch.object(loader, 'PROJECTS', PROJECTS), \
                 patch.object(loader, 'get_client'), patch.object(loader, 'ensure_metadata_table'), \
                 patch.object(loader, 'load_module') as load:
                loader.run_load([project])
                self.assertEqual(load.call_count, 2)
                self.assertEqual(load.call_args.kwargs['project_name'], project)

    def test_load_missing_file_fails(self):
        with patch('loader.os.path.exists', return_value=False):
            with self.assertRaises(FileNotFoundError):
                loader.load_module(MagicMock(), 'A', [], 'ds')

    def test_load_checks_every_id_before_writing(self):
        with patch('loader.os.path.exists', return_value=True), \
             patch('builtins.open', mock_open(read_data='[{"id":"1"},{}]')), \
             patch('loader.ensure_table') as ensure:
            with self.assertRaises(ValueError):
                loader.load_module(MagicMock(), 'A', [], 'ds')
            ensure.assert_not_called()

    def test_empty_load_is_audited_without_merge(self):
        client = MagicMock()
        with patch('loader.os.path.exists', return_value=True), \
             patch('builtins.open', mock_open(read_data='[]')), patch('loader.ensure_table'), \
             patch('loader.write_run') as audit:
            loader.load_module(client, 'A', [], 'ds')
            self.assertEqual(audit.call_args.args[3], 'empty')
            client.query.assert_not_called()

    def test_successful_load_preserves_project_dataset_and_watermark(self):
        for project in PROJECTS:
            with self.subTest(project=project), patch('loader.os.path.exists', return_value=True), \
                 patch('builtins.open', mock_open(read_data='[{"id":"1","Name":"x","Modified_Time":"2026-01-01T00:00:00Z"}]')), \
                 patch('loader.ensure_table'), patch('loader.load_to_staging', return_value=1), \
                 patch('loader.count_insert_update', return_value=(0,1)), patch('loader.write_run') as audit:
                client = MagicMock()
                loader.load_module(client, 'A', ['Name'], 'ds_'+project, project_name=project)
                sql = client.query.call_args.args[0]
                self.assertIn('ds_'+project+'.a', sql)
                self.assertNotIn('THEN DELETE', sql)
                self.assertEqual(audit.call_args.args[3:6], ('success',1,'2026-01-01T00:00:00Z'))

    def test_metadata_rejection_fails(self):
        client = MagicMock()
        client.insert_rows_json.return_value = [{'errors': ['rejected']}]
        with self.assertRaises(RuntimeError):
            metadata.write_run(client, 'giz', 'A', 'success', 1, None, 'ds')

    def test_extraction_failure_attempts_all_then_blocks_caller(self):
        with patch.object(extractor, 'PROJECTS', PROJECTS), patch('extractor.get_client'), \
             patch('extractor.ensure_metadata_table'), patch('extractor.write_run') as audit, \
             patch('extractor.ZohoAuth'), patch('extractor.os.makedirs'), \
             patch('extractor.get_watermark', return_value=None), patch('builtins.open', mock_open()), \
             patch('extractor.extract_module', side_effect=[ValueError('bad'), [], [], []]) as extract:
            with self.assertRaisesRegex(RuntimeError, 'colsubsidio.A'):
                extractor.run_extraction()
            self.assertEqual(extract.call_count, 4)
            self.assertEqual(audit.call_args.args[3], 'error')

    def test_full_refresh_rejects_old_checkpoint(self):
        with patch.object(extractor, 'PROJECTS', {'giz': PROJECTS['giz']}), \
             patch('extractor.get_client'), patch('extractor.ensure_metadata_table'), \
             patch('extractor.write_run') as audit, patch('extractor.ZohoAuth'), \
             patch('extractor.os.makedirs'), patch('extractor.os.path.exists', return_value=True), \
             patch('extractor.extract_module') as extract:
            with self.assertRaises(RuntimeError):
                extractor.run_extraction(['giz'], full_refresh=True)
            extract.assert_not_called()
            self.assertEqual(audit.call_args.args[3], 'reconcile_error')

    def test_main_never_loads_or_builds_after_extraction_failure(self):
        with patch.object(sys, 'argv', ['main.py','giz']), \
             patch('main.run_extraction', side_effect=RuntimeError('partial')), \
             patch('main.run_load') as load, patch('main.subprocess.run') as dbt:
            with self.assertRaises(RuntimeError):
                pipeline.main()
            load.assert_not_called()
            dbt.assert_not_called()

    def test_main_stops_before_dbt_on_load_failure(self):
        with patch.object(sys, 'argv', ['main.py','colsubsidio']), patch('main.run_extraction'), \
             patch('main.run_load', side_effect=RuntimeError('partial')), patch('main.subprocess.run') as dbt:
            with self.assertRaises(RuntimeError):
                pipeline.main()
            dbt.assert_not_called()

    def test_reconcile_cli_validates_before_any_io(self):
        for args in ([], ['inventado'], ['giz','colsubsidio']):
            with self.subTest(args=args), patch.object(sys,'argv',['reconciliar.py']+args), \
                 patch('reconciliar.run_extraction') as extract, patch('reconciliar.get_client') as client:
                with self.assertRaises(SystemExit) as err:
                    reconciliar.main()
                self.assertEqual(err.exception.code, 1)
                extract.assert_not_called()
                client.assert_not_called()

    def test_reconcile_extraction_failure_never_deletes(self):
        with patch.object(sys,'argv',['reconciliar.py','giz']), \
             patch('reconciliar.run_extraction', side_effect=RuntimeError('partial')), \
             patch('reconciliar.reconciliar_module') as reconcile, patch('reconciliar.subprocess.run') as dbt:
            with self.assertRaises(RuntimeError):
                reconciliar.main()
            reconcile.assert_not_called()
            dbt.assert_not_called()

    def test_reconcile_audits_each_outcome(self):
        scenarios = [
            ('missing', None, None, 'reconcile_error', FileNotFoundError),
            ('empty', [], None, 'reconcile_skipped', None),
            ('invalid', [{'id':'1'}, {}], None, 'reconcile_error', ValueError),
            ('blocked', [{'id':'1'}], (False,1,100), 'reconcile_blocked', None),
            ('success', [{'id':'1','Modified_Time':'2026-01-01'}], (True,1,1), 'reconciled', None),
        ]
        for name, records, guard, status, error in scenarios:
            with self.subTest(name=name), ExitStack() as stack:
                stack.enter_context(patch('loader.ensure_metadata_table'))
                stack.enter_context(patch('loader.os.path.exists', return_value=name!='missing'))
                stack.enter_context(patch('builtins.open',mock_open(read_data=json.dumps(records))))
                stack.enter_context(patch('loader.ensure_table'))
                stack.enter_context(patch('loader.load_to_staging',return_value=1))
                stack.enter_context(patch('loader.es_seguro_borrar',return_value=guard))
                audit=stack.enter_context(patch('loader.write_run'))
                client=MagicMock()
                client.query.return_value.result.return_value=[{'n':0}]
                if error:
                    with self.assertRaises(error):
                        loader.reconciliar_module(client,'A',[],'ds',project_name='giz')
                else:
                    self.assertEqual(loader.reconciliar_module(client,'A',[],'ds',project_name='giz'),status)
                self.assertEqual(audit.call_args.args[3],status)
                self.assertEqual(audit.call_args.kwargs['dataset_id'],'ds')
                sql=' '.join(c.args[0] for c in client.query.call_args_list)
                self.assertEqual('THEN DELETE' in sql,name=='success')
                if name=='success':
                    self.assertEqual(audit.call_args.args[5],'2026-01-01')
                if name in ('missing','invalid','empty'):
                    client.query.assert_not_called()

    def test_reconcile_does_not_build_if_blocked_or_error(self):
        for status in ('reconcile_blocked','reconcile_error'):
            with self.subTest(status=status), patch.object(sys,'argv',['reconciliar.py','giz']), \
                 patch('reconciliar.PROJECTS',PROJECTS), patch('reconciliar.run_extraction'), \
                 patch('reconciliar.get_client'), patch('reconciliar.ensure_metadata_table'), \
                 patch('reconciliar.reconciliar_module',return_value=status) as reconcile, \
                 patch('reconciliar.subprocess.run') as dbt:
                with self.assertRaisesRegex(RuntimeError,'giz'):
                    reconciliar.main()
                self.assertEqual(reconcile.call_count,2)
                dbt.assert_not_called()

    def test_reconcile_skipped_allows_dbt(self):
        with patch.object(sys,'argv',['reconciliar.py','colsubsidio']), \
             patch('reconciliar.PROJECTS',PROJECTS), patch('reconciliar.run_extraction'), \
             patch('reconciliar.get_client'), patch('reconciliar.ensure_metadata_table'), \
             patch('reconciliar.reconciliar_module',side_effect=['reconciled','reconcile_skipped']), \
             patch('reconciliar.subprocess.run',return_value=MagicMock(returncode=0)) as dbt:
            reconciliar.main()
            dbt.assert_called_once()
            self.assertEqual(dbt.call_args.args[0][-1],'path:models/colsubsidio')

    def test_freshness_missing_error_and_old_fail(self):
        now=datetime.now(timezone.utc)
        for latest, rows in [(None,[]),(now-timedelta(hours=25),[]),
                             (now,[{'module_name':'A','status':'success'}]),
                             (now,[{'module_name':'A','status':'success'},{'module_name':'B','status':'error'}])]:
            with self.subTest(latest=latest,rows=rows), patch.object(frescura,'PROJECTS',PROJECTS):
                client=MagicMock()
                client.query.side_effect=[MagicMock(result=lambda:[{'ultima_corrida':latest}]),MagicMock(result=lambda:rows)]
                with self.assertRaises(RuntimeError):
                    frescura.verificar(client,'giz',ahora=now)

    def test_freshness_success_and_window(self):
        now=datetime.now(timezone.utc)
        rows=[{'module_name':'A','status':'success'},{'module_name':'B','status':'empty'}]
        for project in PROJECTS:
            with self.subTest(project=project), patch.object(frescura,'PROJECTS',PROJECTS):
                client=MagicMock()
                client.query.side_effect=[MagicMock(result=lambda:[{'ultima_corrida':now}]),MagicMock(result=lambda:rows)]
                start=now-timedelta(minutes=5)
                frescura.verificar(client,project,desde=start,ahora=now)
                for call in client.query.call_args_list:
                    self.assertIn("status in ('success', 'empty', 'error')",call.args[0])
                second=client.query.call_args_list[1]
                self.assertIn('partition by module_name',second.args[0])
                params={p.name:p.value for p in second.kwargs['job_config'].query_parameters if hasattr(p,'value')}
                self.assertEqual(params['inicio'],start)

    def test_freshness_cli_invalid_before_network(self):
        with patch.object(sys,'argv',['verificar_frescura.py','inventado']),patch.object(frescura,'get_client') as client:
            self.assertEqual(frescura.main(),1)
            client.assert_not_called()


if __name__ == '__main__':
    unittest.main()
