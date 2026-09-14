"""La extracción continúa módulos, pero informa el fallo al terminar."""
import unittest
from unittest.mock import patch, mock_open
from extractor import run_extraction


class RunExtractionTest(unittest.TestCase):
    def test_continua_y_falla_al_final(self):
        projects = {'colsubsidio': {'env_prefix':'ZOHO', 'dataset_id':'ds',
                    'modules': {'OK_1':['Name'], 'FALLA':['Name'], 'OK_2':['Name']}}}
        with patch('extractor.PROJECTS',projects), patch('extractor.ZohoAuth'), \
             patch('extractor.get_client'), patch('extractor.ensure_metadata_table'), \
             patch('extractor.write_run'), patch('extractor.get_watermark',return_value=None), \
             patch('extractor.os.makedirs'), patch('builtins.open',mock_open()), \
             patch('extractor.extract_module',side_effect=[[{'id':'1'}],RuntimeError('fallo'),[{'id':'2'}]]) as extract:
            with self.assertRaisesRegex(RuntimeError,'colsubsidio.FALLA'):
                run_extraction(projects=['colsubsidio'])
            self.assertEqual(extract.call_count,3)


if __name__ == '__main__':
    unittest.main()
