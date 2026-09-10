"""Regresión: Empresa escalar solo se serializa en Postvinculación Ruta Mujer."""
import json
import unittest
from unittest.mock import MagicMock, mock_open, patch

import loader


class PostvinculacionEmpresaTest(unittest.TestCase):
    def load_rows(self, project, module, empresa):
        records = [{"id": "1", "Empresa": empresa}]
        with (
            patch("loader.os.path.exists", return_value=True),
            patch("builtins.open", mock_open(read_data=json.dumps(records))),
            patch("loader.ensure_table"),
            patch("loader.load_to_staging", return_value=1) as load,
            patch("loader.count_insert_update", return_value=(0, 1)),
            patch("loader.write_run"),
        ):
            loader.load_module(MagicMock(), module, ["Empresa"],
                               "proyecto_ruta_mujer", project_name=project)
            return load.call_args.args[1]

    def test_texto_se_conserva_como_escalar_json(self):
        value = 'Empresa "Bogotá"'
        rows = self.load_rows("ruta_mujer", "Postvinculaci_n_Colsub", value)
        self.assertEqual(json.loads(rows[0]["Empresa"]), value)

    def test_lookup_y_nulo_se_conservan(self):
        lookup = {"id": "2", "name": "Empresa"}
        rows = self.load_rows("ruta_mujer", "Postvinculaci_n_Colsub", lookup)
        self.assertEqual(json.loads(rows[0]["Empresa"]), lookup)
        rows = self.load_rows("ruta_mujer", "Postvinculaci_n_Colsub", None)
        self.assertIsNone(rows[0]["Empresa"])

    def test_otros_proyectos_y_modulos_no_cambian(self):
        for project, module in [("colsubsidio", "Postvinculaci_n_Colsub"),
                                ("giz", "Postvinculaci_n_Colsub"),
                                ("ruta_mujer", "GE_Agendamiento")]:
            with self.subTest(project=project, module=module):
                rows = self.load_rows(project, module, "Empresa")
                self.assertEqual(rows[0]["Empresa"], "Empresa")


if __name__ == "__main__":
    unittest.main()
