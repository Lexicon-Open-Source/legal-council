"""
Case search and retrieval endpoints for the Virtual Judicial Council.

Provides endpoints for:
- Searching cases (semantic and text-based)
- Retrieving case details
- Getting case statistics
"""

import logging
from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncEngine

from src.council.database import CaseDatabase
from src.council.db.sqlc import ExtractionQuerier
from src.council.dependencies import get_db_engine
from src.council.models.generated import (
    CaseStatisticsResponse,
    GetCaseResponse,
    SearchCasesRequest,
    SearchCasesResponse,
)
from src.council.models.generated import (
    CouncilCaseType as CaseType,
)

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/search", response_model=SearchCasesResponse)
async def search_cases(
    request: SearchCasesRequest,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> SearchCasesResponse:
    """
    Search for cases.

    Supports both semantic search (using embeddings) and text search.
    Semantic search finds conceptually similar cases even if exact
    keywords don't match.

    Optional filters can be applied based on structured case data.
    """
    logger.info(
        f"Searching cases: query='{request.query[:50]}...', "
        f"semantic={request.semantic_search}"
    )

    case_db = CaseDatabase(db_engine)

    # Convert filters if provided
    filters = None
    if request.filters:
        filters = request.filters.model_dump(exclude_none=True)

    cases = await case_db.search_cases(
        query=request.query,
        limit=request.limit,
        semantic_search=request.semantic_search,
        filters=filters,
    )

    return SearchCasesResponse(
        cases=cases,
        total=len(cases),
    )


@router.get("/search", response_model=SearchCasesResponse)
async def search_cases_get(
    query: str,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
    limit: int = Query(default=10, ge=1, le=100),
    semantic: bool = Query(default=True),
    case_type: CaseType | None = Query(default=None),
) -> SearchCasesResponse:
    """
    Search for cases (GET version).

    Simpler version of case search using query parameters.
    """
    logger.info(f"Searching cases (GET): query='{query[:50]}...'")

    case_db = CaseDatabase(db_engine)

    filters = None
    if case_type:
        filters = {"case_type": case_type.value}

    cases = await case_db.search_cases(
        query=query,
        limit=limit,
        semantic_search=semantic,
        filters=filters,
    )

    return SearchCasesResponse(
        cases=cases,
        total=len(cases),
    )


# NOTE: Static routes must be defined BEFORE dynamic routes like /{case_id}
# Otherwise FastAPI will match "/statistics" as case_id="statistics"


@router.get("/statistics", response_model=CaseStatisticsResponse)
async def get_case_statistics(
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> CaseStatisticsResponse:
    """
    Get aggregate statistics about cases in the database.

    Returns:
    - Total number of cases with embeddings
    - Sentence distribution by crime category
    - Verdict distribution
    """
    logger.info("Getting case statistics")

    async with db_engine.connect() as conn:
        querier = ExtractionQuerier(conn)

        # Total cases with embeddings
        total_cases = await querier.count_completed_llm_extractions() or 0

        # Sentence distribution by crime category
        sentence_rows = [row async for row in querier.get_sentence_stats_by_category()]
        sentence_distribution = {
            str(row.category or "Unknown"): {
                "avg_months": round(row.avg_months or 0, 1),
                "count": row.case_count,
            }
            for row in sentence_rows
        }

        # Verdict distribution
        verdict_rows = [row async for row in querier.get_verdict_distribution()]
        verdict_distribution = {
            str(row.verdict_result or "Unknown"): row.case_count for row in verdict_rows
        }

    return CaseStatisticsResponse(
        total_cases=total_cases,
        sentence_distribution=sentence_distribution,
        verdict_distribution=verdict_distribution,
    )


@router.get("/by-type/{case_type}", response_model=SearchCasesResponse)
async def get_cases_by_type(
    case_type: CaseType,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> SearchCasesResponse:
    """
    Get cases filtered by case type.

    A convenience endpoint for filtering by narcotics, corruption,
    or other case types.
    """
    logger.info(f"Getting cases by type: {case_type.value}")

    # Map case type to search patterns
    type_patterns = {
        CaseType.NARCOTICS: "%narkotika%",
        CaseType.CORRUPTION: "%korupsi%",
    }

    case_db = CaseDatabase(db_engine)

    async with db_engine.connect() as conn:
        querier = ExtractionQuerier(conn)

        if case_type in [CaseType.NARCOTICS, CaseType.CORRUPTION]:
            # Search for specific types using SQLC query
            pattern = type_patterns.get(case_type, f"%{case_type.value}%")
            total = await querier.count_cases_by_type_pattern(type_pattern=pattern)
            rows = [
                row
                async for row in querier.get_cases_by_type_pattern(
                    type_pattern=pattern,
                    limit_val=limit,
                    offset_val=offset,
                )
            ]
        else:
            # Get all cases for general/other using SQLC query
            total = await querier.count_all_cases()
            rows = [
                row
                async for row in querier.get_all_cases(
                    limit=limit,
                    offset=offset,
                )
            ]

    # Convert to case records using generic converter
    cases = [record for row in rows if (record := case_db.row_to_case_record(row))]

    return SearchCasesResponse(
        cases=cases,
        total=total or 0,
    )


# Dynamic catch-all route - MUST be last to avoid matching static routes
@router.get("/{case_id}", response_model=GetCaseResponse)
async def get_case(
    case_id: str,
    db_engine: Annotated[AsyncEngine, Depends(get_db_engine)],
) -> GetCaseResponse:
    """
    Get a case by ID.

    Returns the full case record including extraction results,
    summaries, and verdict information.
    """
    logger.info(f"Getting case: {case_id}")

    case_db = CaseDatabase(db_engine)
    case = await case_db.get_case(case_id)

    if not case:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail=f"Case not found: {case_id}",
        )

    return GetCaseResponse(case=case)
