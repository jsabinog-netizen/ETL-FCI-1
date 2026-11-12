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


def test_extract_module_pasa_a_page_token_despues_de_2000():
    """Zoho corta en 2000 registros con `page`: la página 11 debe ir con el token de la 10."""
    paginas = [([{"id": n}], True, f"tok_{n}") for n in range(1, 11)]
    paginas.append(([{"id": 11}], False, None))

    with patch("extractor.fetch_page", side_effect=paginas) as mock_fetch:
        registros = extract_module(make_auth(), MODULE, FIELDS)

    assert [r["id"] for r in registros] == list(range(1, 12))
    tokens = [c.kwargs.get("page_token") for c in mock_fetch.call_args_list]
    assert tokens[:10] == [None] * 10, "las primeras 10 páginas van con `page`, sin token"
    assert tokens[10] == "tok_10"


def test_extract_module_sin_token_en_pagina_11_falla_claro():
    paginas = [([{"id": n}], True, None) for n in range(1, 11)]
    with patch("extractor.fetch_page", side_effect=paginas):
        try:
            extract_module(make_auth(), MODULE, FIELDS)
        except RuntimeError as e:
            assert "next_page_token" in str(e)
        else:
            raise AssertionError("debía fallar sin token en la página 11")
    os.remove(f"checkpoints/{MODULE}.json")


def test_extract_module_reanuda_con_token_sin_repetir_pagina():
    """El checkpoint guarda la última página procesada y el token de la siguiente."""
    import json
    os.makedirs("checkpoints", exist_ok=True)
    with open(f"checkpoints/{MODULE}.json", "w") as f:
        json.dump({"page": 10, "records": [{"id": n} for n in range(1, 11)],
                   "next_page_token": "tok_10"}, f)

    with patch("extractor.fetch_page", return_value=([{"id": 11}], False, None)) as mock_fetch:
        registros = extract_module(make_auth(), MODULE, FIELDS)

    assert mock_fetch.call_count == 1
    assert mock_fetch.call_args.kwargs["page"] == 11
    assert mock_fetch.call_args.kwargs["page_token"] == "tok_10"
    assert [r["id"] for r in registros] == list(range(1, 12))


def test_fetch_page_con_token_no_envia_page():
    from extractor import fetch_page
    response = MagicMock(status_code=200)
    response.json.return_value = {"data": [], "info": {"more_records": False}}
    with patch("extractor.requests.get", return_value=response) as get:
        fetch_page(make_auth(), MODULE, FIELDS, page=11, page_token="tok_10")
    params = get.call_args.kwargs["params"]
    assert params["page_token"] == "tok_10"
    assert "page" not in params, "Zoho rechaza page + page_token juntos"


if __name__ == "__main__":
    test_extract_module_pagina_multiple()
    test_extract_module_borra_checkpoint_al_terminar()
    test_extract_module_chunking_mas_de_45_campos()
    test_extract_module_pasa_a_page_token_despues_de_2000()
    test_extract_module_sin_token_en_pagina_11_falla_claro()
    test_extract_module_reanuda_con_token_sin_repetir_pagina()
    test_fetch_page_con_token_no_envia_page()
    print("\n✓ Todos los tests pasaron")

