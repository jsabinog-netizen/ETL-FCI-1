import os 

from unittest.mock import patch, MagicMock
from extractor import extract_module


def make_auth():
    """Crea un auth falso que no toca .env ni Zoho."""
    auth = MagicMock()
    auth.renew_token.return_value = {"Authorization": "Zoho-oauthtoken fake_token"}
    return auth

FIELDS = ["Name", "Municipio"]
MODULE = "Registro_empresas"

def test_extract_module_pagina_multiple():
    paginas_simuladas = [
        ([{"id": 1}], True, None),
        ([{"id": 2}], True, None),
        ([{"id": 3}], False, None),
    ]

    with patch("extractor.fetch_page", side_effect=paginas_simuladas) as mock_fetch:
        registros = extract_module(make_auth(), MODULE, FIELDS)

    assert len(registros) == 3
    assert registros == [{"id": 1}, {"id": 2}, {"id": 3}]
    assert mock_fetch.call_count == 3
    print("✓ test_extract_module_pagina_multiple pasó")

def test_extract_module_borra_checkpoint_al_terminar():
    paginas_simuladas = [
        ([{"id": 1}], True, None),
        ([{"id": 2}], False, None),
    ]

    checkpoint_file = "checkpoints/Registro_empresas.json"

    with patch("extractor.fetch_page", side_effect=paginas_simuladas):
        extract_module(make_auth(), MODULE, FIELDS)

    # Después de terminar con éxito, el checkpoint NO debe existir
    assert not os.path.exists(checkpoint_file), "El checkpoint debería haberse borrado"
    print("✓ test_extract_module_borra_checkpoint_al_terminar pasó")

def test_extract_module_chunking_mas_de_45_campos():
    """Verifica que si un módulo supera 45 campos, se divide en lotes de <=40 y se fusionan por id."""
    campos_65 = [f"campo_{i}" for i in range(65)]
    
    # 2 lotes (40 campos + 25 campos), cada uno con 1 página simulada
    lote1_data = [{"id": "100", "campo_0": "valor_a"}, {"id": "200", "campo_0": "valor_b"}]
    lote2_data = [{"id": "100", "campo_50": "valor_extra_a"}, {"id": "200", "campo_50": "valor_extra_b"}]

    respuestas = [
        (lote1_data, False, None),
        (lote2_data, False, None),
    ]

    with patch("extractor.fetch_page", side_effect=respuestas) as mock_fetch:
        registros = extract_module(make_auth(), MODULE, campos_65)

    assert mock_fetch.call_count == 2
    # Verificar que ningún lote enviado a fetch_page superó los 40 campos
    for call in mock_fetch.call_args_list:
        fields_arg = call.kwargs.get("fields") or call.args[2]
        assert len(fields_arg) <= 40, f"Un lote superó los 40 campos: {len(fields_arg)}"

    # Verificar que los datos se fusionaron correctamente por id
    assert len(registros) == 2
    rec_100 = next(r for r in registros if r["id"] == "100")
    rec_200 = next(r for r in registros if r["id"] == "200")
    assert rec_100["campo_0"] == "valor_a"
    assert rec_100["campo_50"] == "valor_extra_a"
    assert rec_200["campo_0"] == "valor_b"
    assert rec_200["campo_50"] == "valor_extra_b"
    print("✓ test_extract_module_chunking_mas_de_45_campos pasó")


if __name__ == "__main__":
    test_extract_module_pagina_multiple()
    test_extract_module_borra_checkpoint_al_terminar()
    test_extract_module_chunking_mas_de_45_campos()
    print("\n✓ Todos los tests pasaron")

