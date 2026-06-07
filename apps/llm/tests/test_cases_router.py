"""
Unit tests for case router helpers.
"""

import pytest

from src.council.models.generated import CouncilCaseType
from src.council.routers import cases as cases_router


class _FakeConnection:
    async def __aenter__(self):
        return object()

    async def __aexit__(self, exc_type, exc, tb):
        return False


class _FakeEngine:
    def connect(self):
        return _FakeConnection()


class _FakeCaseDatabase:
    def __init__(self, db_engine):
        self.db_engine = db_engine

    def row_to_case_record(self, row):
        return {
            "id": row.extraction_id,
            "case_type": CouncilCaseType.CORRUPTION,
            "is_landmark_case": False,
        }


class _FakeRow:
    def __init__(self, extraction_id):
        self.extraction_id = extraction_id


class _FakeExtractionQuerier:
    def __init__(self, conn):
        self.conn = conn

    async def count_cases_by_type_pattern(self, *, type_pattern):
        return 42

    async def get_cases_by_type_pattern(self, *, type_pattern, limit_val, offset_val):
        yield _FakeRow("case-page-1")

    async def count_all_cases(self):
        return 99

    async def get_all_cases(self, *, limit, offset):
        yield _FakeRow("case-page-2")


@pytest.mark.asyncio
async def test_get_cases_by_type_reports_total_matches_not_page_size(monkeypatch):
    monkeypatch.setattr(cases_router, "CaseDatabase", _FakeCaseDatabase)
    monkeypatch.setattr(cases_router, "ExtractionQuerier", _FakeExtractionQuerier)

    response = await cases_router.get_cases_by_type(
        case_type=CouncilCaseType.CORRUPTION,
        db_engine=_FakeEngine(),
        limit=1,
        offset=20,
    )

    assert len(response.cases) == 1
    assert response.total == 42


@pytest.mark.asyncio
async def test_get_cases_by_type_reports_all_case_total_for_other(monkeypatch):
    monkeypatch.setattr(cases_router, "CaseDatabase", _FakeCaseDatabase)
    monkeypatch.setattr(cases_router, "ExtractionQuerier", _FakeExtractionQuerier)

    response = await cases_router.get_cases_by_type(
        case_type=CouncilCaseType.OTHER,
        db_engine=_FakeEngine(),
        limit=1,
        offset=20,
    )

    assert len(response.cases) == 1
    assert response.total == 99
