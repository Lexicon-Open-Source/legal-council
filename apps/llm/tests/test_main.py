from main import prepare_asyncpg_url


def test_prepare_asyncpg_url_converts_postgres_scheme_and_removes_sslmode():
    url = "postgres://user:pass@localhost:5432/lexicon?sslmode=disable"

    assert (
        prepare_asyncpg_url(url)
        == "postgresql+asyncpg://user:pass@localhost:5432/lexicon"
    )


def test_prepare_asyncpg_url_converts_postgresql_scheme_and_preserves_other_params():
    url = "postgresql://user:pass@localhost:5432/lexicon?sslmode=disable&foo=bar"

    assert (
        prepare_asyncpg_url(url)
        == "postgresql+asyncpg://user:pass@localhost:5432/lexicon?foo=bar"
    )
