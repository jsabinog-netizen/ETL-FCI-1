"""Propagación incremental de borrados Zoho → raw (borrados.py) y su lugar en main.py."""
import sys
import unittest
from unittest.mock import MagicMock, patch

import borrados
import main as pipeline


def resp(status, body=None):
    r = MagicMock(status_code=status)
    r.json.return_value = body or {}
    r.text = str(body)
    return r


class FetchDeletedIdsTest(unittest.TestCase):
    def test_204_es_lista_vacia(self):
        with patch("borrados.requests.get", return_value=resp(204)):
            self.assertEqual(borrados.fetch_deleted_ids(MagicMock(), "M"), [])

    def test_pagina_hasta_que_no_hay_mas(self):
        paginas = [
            resp(200, {"data": [{"id": "1"}, {"id": "2"}], "info": {"more_records": True}}),
            resp(200, {"data": [{"id": "3"}], "info": {"more_records": False}}),
        ]
        with patch("borrados.requests.get", side_effect=paginas) as get:
            self.assertEqual(borrados.fetch_deleted_ids(MagicMock(), "M"), ["1", "2", "3"])
        self.assertEqual([c.kwargs["params"]["page"] for c in get.call_args_list], [1, 2])
        self.assertTrue(all(c.kwargs["params"]["type"] == "all" for c in get.call_args_list))

    def test_error_http_se_propaga(self):
        with patch("borrados.requests.get", return_value=resp(500)), patch("extractor.time.sleep"):
            with self.assertRaises(Exception):
                borrados.fetch_deleted_ids(MagicMock(), "M")


class DeleteFromRawTest(unittest.TestCase):
    def test_sin_ids_no_consulta(self):
        client = MagicMock()
        self.assertEqual(borrados.delete_from_raw(client, "ds", "Modulo_X", []), 0)
        client.query.assert_not_called()

    def test_borra_con_parametro_y_tabla_del_modulo(self):
        client = MagicMock()
        client.query.return_value.num_dml_affected_rows = 2
        n = borrados.delete_from_raw(client, "proyecto_ruta_mujer", "Psicosocial_RutaM_v2", ["1", "2"])
        self.assertEqual(n, 2)
        sql = client.query.call_args.args[0]
        self.assertIn("proyecto_ruta_mujer.psicosocial_rutam_v2", sql)
        self.assertIn("UNNEST(@ids)", sql)  # nunca ids interpolados en el SQL
        self.assertNotIn("'1'", sql)


class PropagarBorradosTest(unittest.TestCase):
    def test_un_modulo_falla_los_demas_siguen_y_al_final_levanta(self):
        def fetch(auth, module_name):
            if module_name == "B":
                raise RuntimeError("zoho caído")
            return ["9"]

        with patch("borrados.fetch_deleted_ids", side_effect=fetch), \
             patch("borrados.delete_from_raw", return_value=1) as delete, \
             patch("borrados.write_run") as audit:
            with self.assertRaises(RuntimeError):
                borrados.propagar_borrados(MagicMock(), MagicMock(), "ruta_mujer", "ds", ["A", "B", "C"])

        self.assertEqual([c.args[2] for c in delete.call_args_list], ["A", "C"])
        estados = {c.args[2]: c.args[3] for c in audit.call_args_list}
        self.assertEqual(estados, {"A": "deleted", "B": "delete_error", "C": "deleted"})
        # watermark NULL: no puede mover el since del incremental
        self.assertTrue(all(c.args[5] is None for c in audit.call_args_list))


class MainBorradosTest(unittest.TestCase):
    def run_main(self, project, propagar_side_effect=None):
        with patch.object(sys, "argv", ["main.py", project]), \
             patch("main.run_extraction"), patch("main.run_load"), \
             patch("main.get_client"), patch("main.ZohoAuth"), \
             patch("main.propagar_borrados", side_effect=propagar_side_effect) as propagar, \
             patch("main.subprocess.run", return_value=MagicMock(returncode=0)) as dbt:
            try:
                pipeline.main()
                code = 0
            except SystemExit as e:
                code = e.code
        return propagar, dbt, code

    def test_ruta_mujer_propaga_antes_de_dbt(self):
        propagar, dbt, code = self.run_main("ruta_mujer")
        propagar.assert_called_once()
        self.assertEqual(propagar.call_args.args[2], "ruta_mujer")
        dbt.assert_called_once()
        self.assertEqual(code, 0)

    def test_fallo_de_borrados_no_bloquea_dbt_pero_termina_en_error(self):
        propagar, dbt, code = self.run_main("ruta_mujer", RuntimeError("incompleto"))
        dbt.assert_called_once()
        self.assertEqual(code, 1)

    def test_produccion_no_propaga(self):
        for project in ("colsubsidio", "giz"):
            with self.subTest(project=project):
                propagar, dbt, code = self.run_main(project)
                propagar.assert_not_called()
                self.assertEqual(code, 0)


if __name__ == "__main__":
    unittest.main()
