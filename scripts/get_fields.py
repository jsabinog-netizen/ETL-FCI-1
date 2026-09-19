"""
scripts/get_fields.py — Inspección de campos reales en Zoho CRM.
Uso: python scripts/get_fields.py <Nombre_Modulo> [proyecto]
Ejemplo: python scripts/get_fields.py Inscripci_n_Colsubsidios ruta_mujer
"""
import sys
import requests
from dotenv import load_dotenv
from config import PROJECTS
from auth import ZohoAuth

load_dotenv()

def main():
    if len(sys.argv) < 2:
        print("Uso: python scripts/get_fields.py <Nombre_Modulo> [colsubsidio|giz|ruta_mujer]")
        sys.exit(1)

    module_name = sys.argv[1]
    project = sys.argv[2] if len(sys.argv) > 2 else "ruta_mujer"

    if project not in PROJECTS:
        print(f"Proyecto desconocido: {project}")
        sys.exit(1)

    env_prefix = PROJECTS[project]["env_prefix"]
    auth = ZohoAuth(env_prefix=env_prefix)
    
    url = "https://www.zohoapis.com/crm/v8/settings/fields"
    params = {"module": module_name}
    
    response = requests.get(url, headers=auth.get_header(), params=params)
    if response.status_code != 200:
        print(f"Error {response.status_code}: {response.text}")
        sys.exit(1)

    fields_data = response.json().get("fields", [])
    print(f"\n--- {module_name} ({len(fields_data)} campos encontrados en Zoho) ---")
    for field in sorted(fields_data, key=lambda x: x.get("api_name", "")):
        api_name = field.get("api_name")
        data_type = field.get("data_type")
        label = field.get("display_label")
        print(f"{api_name:<45} | {data_type:<15} | {label}")

if __name__ == "__main__":
    main()