"""Agregar columnas raw de Ruta Mujer antes de reextraer; no borra datos.

Ejecutar desde la raíz: python scripts/migrar_esquema_ruta_mujer.py
El cargador compartido solo crea tablas; no evoluciona tablas existentes.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from google.api_core.exceptions import NotFound
from google.cloud import bigquery
import requests
from auth import ZohoAuth
from config import MODULES_RUTA_MUJER, PROJECT_ID
from loader import build_raw_schema, get_client


def validate_fields_against_zoho(modules_dict, env_prefix="ZOHO"):
    """
    Valida que todos los campos definidos en config.py existan realmente en Zoho CRM.
    Si algún campo no existe, detiene la ejecución inmediatamente para evitar contaminar BigQuery.
    """
    auth = ZohoAuth(env_prefix=env_prefix)
    headers = auth.get_header()
    base_url = "https://www.zohoapis.com/crm/v8/settings/fields"
    invalid = {}

    for module, fields in modules_dict.items():
        resp = requests.get(f"{base_url}?module={module}", headers=headers)
        if resp.status_code != 200:
            raise RuntimeError(f"Error consultando metadata de Zoho para {module}: {resp.status_code} - {resp.text}")
        zoho_api_names = {f["api_name"] for f in resp.json().get("fields", [])}
        resp_unused = requests.get(f"{base_url}?module={module}&type=unused", headers=headers)
        if resp_unused.status_code == 200:
            zoho_api_names |= {f["api_name"] for f in resp_unused.json().get("fields", [])}

        missing = [f for f in fields if f not in zoho_api_names]
        if missing:
            invalid[module] = missing

    if invalid:
        msg_lines = ["❌ VALIDACIÓN FALLIDA: Los siguientes api_names en config.py NO existen en Zoho CRM:"]
        for mod, mis in invalid.items():
            msg_lines.append(f"  • Módulo {mod}: {mis}")
        raise ValueError("\n".join(msg_lines))
    print("Validacion Zoho CRM exitosa: Todos los api_names existen en Zoho.")


def main():
    # Validar primero contra Zoho CRM antes de tocar BigQuery
    validate_fields_against_zoho(MODULES_RUTA_MUJER, env_prefix="ZOHO")

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
