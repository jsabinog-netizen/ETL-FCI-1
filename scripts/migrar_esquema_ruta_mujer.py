"""Agregar columnas raw de Ruta Mujer antes de reextraer; no borra datos.

Ejecutar desde la raíz: python scripts/migrar_esquema_ruta_mujer.py
El cargador compartido solo crea tablas; no evoluciona tablas existentes.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from google.api_core.exceptions import NotFound
from google.cloud import bigquery
from config import MODULES_RUTA_MUJER, PROJECT_ID
from loader import build_raw_schema, get_client


def main():
    client = get_client()
    for module, fields in MODULES_RUTA_MUJER.items():
        table_id = f"{PROJECT_ID}.proyecto_ruta_mujer.{module.lower()}"
        expected = build_raw_schema(fields)
        assert len({f.name.lower() for f in expected}) == len(expected)
        try:
            table = client.get_table(table_id)
        except NotFound:
            client.create_table(bigquery.Table(table_id, schema=expected))
            print(f"{module}: tabla creada")
            continue
        existing = {f.name.lower(): f for f in table.schema}
        for field in expected:
            if field.name.lower() in existing:
                actual = existing[field.name.lower()]
                if actual.field_type != field.field_type:
                    raise ValueError(f"{table_id}.{field.name}: tipo incompatible {actual.field_type}")
        added = [f for f in expected if f.name.lower() not in existing]
        if added:
            table.schema = list(table.schema) + added
            client.update_table(table, ["schema"])
        print(f"{module}: agregadas {[f.name for f in added]}")


if __name__ == "__main__":
    main()
