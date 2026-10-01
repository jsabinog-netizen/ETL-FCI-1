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


class EnsureTableSchemaEvolutionTest(unittest.TestCase):
    def test_crea_tabla_si_no_existe(self):
        client = MagicMock()
        client.get_table.side_effect = Exception("Not found")
        schema = [MagicMock(name="id"), MagicMock(name="campo_a")]

        loader.ensure_table(client, "project.dataset.tabla", schema)
        client.create_table.assert_called_once()

    def test_agrega_columnas_faltantes_si_existe(self):
        client = MagicMock()
        existing_table = MagicMock()
        f_id = MagicMock()
        f_id.name = "id"
        existing_table.schema = [f_id]
        client.get_table.return_value = existing_table

        f_new = MagicMock()
        f_new.name = "nuevo_campo"
        schema = [f_id, f_new]

        loader.ensure_table(client, "project.dataset.tabla", schema)
        client.update_table.assert_called_once_with(existing_table, ["schema"])
        self.assertIn(f_new, existing_table.schema)

    def test_no_actualiza_si_schema_ya_tiene_todas_las_columnas(self):
        client = MagicMock()
        existing_table = MagicMock()
        f_id = MagicMock()
        f_id.name = "id"
        existing_table.schema = [f_id]
        client.get_table.return_value = existing_table

        loader.ensure_table(client, "project.dataset.tabla", [f_id])
        client.update_table.assert_not_called()


if __name__ == "__main__":
    unittest.main()
