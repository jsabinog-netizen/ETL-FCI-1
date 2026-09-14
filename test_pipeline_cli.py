"""Contratos CLI y propagación real extract_module -> fetch_page -> HTTP."""
import ast
import io
import unittest
from contextlib import redirect_stderr, redirect_stdout
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import MagicMock, patch, mock_open
import extractor
import main as pipeline
import metadata
from pipeline_cli import select_projects

PROJECTS={'colsubsidio':{},'giz':{},'ruta_mujer':{}}

class PipelineCliTest(unittest.TestCase):
    def test_requires_explicit_selection(self):
        for allow_all in (False,True):
            for args in ([],['inventado'],['giz','colsubsidio'],['--all','giz']):
                with self.subTest(args=args,all=allow_all),redirect_stdout(io.StringIO()),redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as e:
                        select_projects(PROJECTS,allow_all,argv=args)
                    self.assertEqual(e.exception.code,1)
        with redirect_stdout(io.StringIO()),redirect_stderr(io.StringIO()),self.assertRaises(SystemExit):
            select_projects(PROJECTS,argv=['--all'])

    def test_project_and_deliberate_all(self):
        self.assertEqual(select_projects(PROJECTS,argv=['giz']),['giz'])
        self.assertEqual(select_projects(PROJECTS,True,argv=['--all']),list(PROJECTS))

    def test_main_all_passes_explicit_list_to_all_stages(self):
        with patch.object(pipeline,'PROJECTS',PROJECTS),patch('sys.argv',['main.py','--all']), \
             patch.object(pipeline,'run_extraction') as extract,patch.object(pipeline,'run_load') as load, \
             patch('main.subprocess.run',return_value=MagicMock(returncode=0)) as dbt:
            pipeline.main()
            extract.assert_called_once_with(projects=list(PROJECTS),full_refresh=False)
            load.assert_called_once_with(projects=list(PROJECTS))
            self.assertEqual([c.args[0][-1] for c in dbt.call_args_list],['path:models/'+p for p in PROJECTS])

    def test_main_invalid_does_not_call_services(self):
        with patch('sys.argv',['main.py']),patch.object(pipeline,'run_extraction') as extract, \
             patch.object(pipeline,'run_load') as load,patch('main.subprocess.run') as dbt, \
             redirect_stdout(io.StringIO()),redirect_stderr(io.StringIO()),self.assertRaises(SystemExit):
            pipeline.main()
        extract.assert_not_called();load.assert_not_called();dbt.assert_not_called()

    def test_standalone_entrypoints_pass_chosen_project(self):
        root=Path(__file__).resolve().parent
        for file,call in [('extractor.py','run_extraction'),('loader.py','run_load')]:
            tree=ast.parse((root/file).read_text(encoding='utf-8'))
            block=tree.body[-1]
            self.assertIsInstance(block,ast.If)
            for project in ('giz','colsubsidio'):
                fn=MagicMock()
                with patch('sys.argv',[file,project]):
                    exec(compile(ast.Module(body=[block],type_ignores=[]),file,'exec'),
                         {'__name__':'__main__','PROJECTS':PROJECTS,call:fn})
                if call=='run_load':fn.assert_called_once_with([project])
                else:fn.assert_called_once_with(projects=[project])

    def test_since_propagates_through_every_page(self):
        since='2026-08-15T21:25:27+00:00'
        pages=[]
        for i in (1,2):
            response=MagicMock(status_code=200)
            response.json.return_value={'data':[{'id':str(i)}],'info':{'more_records':i==1}}
            pages.append(response)
        auth=MagicMock();auth.get_header.side_effect=lambda:{'Authorization':'fake'}
        with patch('extractor.os.makedirs'),patch('extractor.os.path.exists',return_value=False), \
             patch('builtins.open',mock_open()),patch('extractor.requests.get',side_effect=pages) as get:
            rows=extractor.extract_module(auth,'Transferencia',['Modified_Time'],since=since)
        self.assertEqual(rows,[{'id':'1'},{'id':'2'}])
        self.assertEqual([c.kwargs['params']['page'] for c in get.call_args_list],[1,2])
        for c in get.call_args_list:
            self.assertEqual(c.kwargs['headers']['If-Modified-Since'],since)
            self.assertEqual(c.kwargs['params']['sort_by'],'Modified_Time')
            self.assertEqual(c.kwargs['params']['sort_order'],'asc')

    def test_full_refresh_has_no_time_filter(self):
        auth=MagicMock();auth.get_header.return_value={}
        response=MagicMock(status_code=204)
        with patch('extractor.os.makedirs'),patch('extractor.os.path.exists',return_value=False), \
             patch('builtins.open',mock_open()),patch('extractor.requests.get',return_value=response) as get:
            self.assertEqual(extractor.extract_module(auth,'Transferencia',[],since=None),[])
        self.assertNotIn('If-Modified-Since',get.call_args.kwargs['headers'])
        self.assertNotIn('sort_by',get.call_args.kwargs['params'])

    def test_watermark_is_iso_string_with_offset(self):
        client=MagicMock()
        client.query.return_value.result.return_value=[{'since':datetime(2026,9,9,17,29,18,tzinfo=timezone.utc)}]
        self.assertEqual(metadata.get_watermark(client,'colsubsidio','Transferencia','ds'),'2026-09-09T17:29:18+00:00')

if __name__=='__main__':
    unittest.main()
