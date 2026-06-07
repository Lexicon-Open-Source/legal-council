"""
Database operations for the Virtual Judicial Council.

Provides:
- Session storage and retrieval with PostgreSQL persistence (using SQLC)
- Similar case search using pgvector embeddings
- Case data access from llm_extractions table
"""

import json
import logging
from typing import Any
from uuid import uuid4

import sqlalchemy
from sqlalchemy.ext.asyncio import AsyncEngine

from src.council.db.sqlc import (
    ExtractionQuerier,
    FindSimilarCasesByEmbeddingRow,
)
from src.council.db.sqlc.council import (
    AsyncQuerier as CouncilQuerier,
)
from src.council.db.sqlc.council import (
    CouncilV1DeliberationMessage,
    CouncilV1DeliberationSession,
    CreateCouncilMessageParams,
    CreateCouncilSessionParams,
    UpdateCouncilSessionParams,
)
from src.council.models.generated import (
    AgentId,
    AgentSender,
    CaseInput,
    CaseRecord,
    DeliberationMessage,
    DeliberationSession,
    InputType,
    ParsedCaseInput,
    SessionStatus,
    SystemSender,
    UserSender,
)
from src.council.models.generated import (
    CouncilCaseType as CaseType,
)
from src.council.models.generated import (
    CouncilSimilarCase as SimilarCase,
)
from src.council.services.embeddings import (
    get_council_embedding_service,
)

logger = logging.getLogger(__name__)


# =============================================================================
# Conversion Helpers
# =============================================================================


def _determine_case_type(crime_category: str | None) -> CaseType:
    """
    Determine case type from crime category string.

    Args:
        crime_category: The crime category string from extraction result

    Returns:
        CaseType enum value based on the category
    """
    category = (crime_category or "").lower()
    if "narkotika" in category or "narcotics" in category:
        return CaseType.NARCOTICS
    elif "korupsi" in category or "corruption" in category:
        return CaseType.CORRUPTION
    elif category:
        return CaseType.GENERAL_CRIMINAL
    return CaseType.OTHER


def _case_type_filter_patterns(case_type: Any) -> list[str]:
    """Return database crime-category patterns for an API case type."""
    if hasattr(case_type, "value"):
        case_type = case_type.value

    normalized = str(case_type or "").strip().lower()
    if not normalized:
        return []

    terms_by_case_type = {
        CaseType.CORRUPTION.value: ["korupsi", "corruption"],
        "korupsi": ["korupsi", "corruption"],
        CaseType.NARCOTICS.value: ["narkotika", "narcotics"],
        "narkotika": ["narkotika", "narcotics"],
    }

    terms = terms_by_case_type.get(normalized, [normalized])
    return [f"%{term}%" for term in terms]


def _extract_common_case_data(extraction_result: dict) -> dict:
    """
    Extract common case data from extraction result dict.

    This consolidates the repeated dict traversal logic used across
    multiple row conversion methods.

    Args:
        extraction_result: The extraction_result dict from a database row

    Returns:
        Dictionary with extracted case_meta, court, defendant, verdict,
        case_number, crime_category, and case_type
    """
    result = extraction_result or {}
    case_meta = result.get("case_metadata", {}) or {}
    court = result.get("court", {}) or {}
    defendant = result.get("defendant", {}) or {}
    verdict = result.get("verdict", {}) or {}

    # Extract case number from court info (primary) or case_metadata (fallback)
    case_number = (
        court.get("verdict_number")
        or court.get("case_register_number")
        or case_meta.get("case_number")
    )

    # Get crime category for case type determination
    crime_category = (
        case_meta.get("crime_category") or result.get("crime_category") or ""
    )

    return {
        "result": result,
        "case_meta": case_meta,
        "court": court,
        "defendant": defendant,
        "verdict": verdict,
        "case_number": case_number,
        "crime_category": crime_category,
        "case_type": _determine_case_type(crime_category),
    }


def _sender_to_dict(sender: UserSender | AgentSender | SystemSender) -> dict:
    """Convert a MessageSender to a dictionary for JSONB storage."""
    if isinstance(sender, AgentSender):
        return {"type": "agent", "agent_id": sender.agent_id.value}
    elif isinstance(sender, UserSender):
        return {"type": "user"}
    else:
        return {"type": "system"}


def _dict_to_sender(data: dict) -> UserSender | AgentSender | SystemSender:
    """Convert a dictionary from JSONB to a MessageSender.

    Handles graceful fallback for unknown agent_id values to prevent
    session retrieval failures during code rollbacks or schema changes.
    """
    sender_type = data.get("type")
    if sender_type == "agent":
        if "agent_id" not in data:
            logger.error("Missing agent_id for agent sender")
            return SystemSender(type="system")
        try:
            agent_id = AgentId(data.get("agent_id", ""))
            return AgentSender(type="agent", agent_id=agent_id)
        except ValueError:
            logger.warning(
                f"Unknown agent_id: {data.get('agent_id')}, defaulting to SystemSender"
            )
            return SystemSender(type="system")
    elif sender_type == "user":
        return UserSender(type="user")
    else:
        if sender_type not in ("system", None):
            logger.warning(
                f"Unknown sender type: {sender_type}, defaulting to SystemSender"
            )
        return SystemSender(type="system")


def _sqlc_session_to_schema(
    db_session: CouncilV1DeliberationSession,
    messages: list[CouncilV1DeliberationMessage],
) -> DeliberationSession:
    """Convert SQLC models to Pydantic schema."""
    # Convert messages (already sorted by sequence_number from DB query)
    schema_messages = [
        DeliberationMessage(
            id=msg.id,
            session_id=msg.session_id,
            sender=_dict_to_sender(msg.sender if isinstance(msg.sender, dict) else {}),
            content=msg.content,
            intent=msg.intent,
            cited_cases=msg.cited_cases if isinstance(msg.cited_cases, list) else [],
            cited_laws=msg.cited_laws if isinstance(msg.cited_laws, list) else [],
            timestamp=msg.timestamp,
        )
        for msg in messages
    ]

    # Convert case_input from dict/Any to CaseInput
    case_input_data = db_session.case_input
    try:
        if isinstance(case_input_data, str):
            case_input_data = json.loads(case_input_data)
        case_input = CaseInput(
            input_type=InputType(case_input_data["input_type"]),
            raw_input=case_input_data["raw_input"],
            parsed_case=ParsedCaseInput.model_validate(case_input_data["parsed_case"]),
        )
    except (json.JSONDecodeError, KeyError, TypeError, ValueError) as e:
        logger.error(f"Failed to parse case_input for session {db_session.id}: {e}")
        raise ValueError(f"Malformed case_input data: {e}") from e

    # Convert similar_cases from list of dicts to list of SimilarCase
    # Handle None, empty list, or string JSON explicitly
    similar_cases_data = db_session.similar_cases
    similar_cases: list[SimilarCase] = []
    if similar_cases_data is not None:
        try:
            if isinstance(similar_cases_data, str):
                similar_cases_data = json.loads(similar_cases_data)
            if isinstance(similar_cases_data, list):
                similar_cases = [
                    SimilarCase.model_validate(sc) for sc in similar_cases_data
                ]
        except (json.JSONDecodeError, TypeError, ValueError) as e:
            logger.warning(
                f"Failed to parse similar_cases for session {db_session.id}: {e}"
            )
            # Non-fatal: continue with empty list

    return DeliberationSession(
        id=db_session.id,
        user_id=db_session.user_id,
        status=SessionStatus(db_session.status),
        case_input=case_input,
        similar_cases=similar_cases,
        messages=schema_messages,
        legal_opinion=db_session.legal_opinion,
        created_at=db_session.created_at,
        updated_at=db_session.updated_at,
        concluded_at=db_session.concluded_at,
    )


# =============================================================================
# Database Session Store (SQLC-based)
# =============================================================================


class SessionStore:
    """
    Database-backed store for deliberation sessions.

    Persists sessions and messages to PostgreSQL using SQLC-generated queries.
    All methods are async to support database operations.
    """

    def __init__(self, db_engine: AsyncEngine):
        """
        Initialize the session store with a database engine.

        Args:
            db_engine: SQLAlchemy async engine for database operations
        """
        self._db_engine = db_engine
        logger.info("Database session store initialized (SQLC)")

    async def create_session(
        self,
        case_input: CaseInput,
        user_id: str | None = None,
    ) -> DeliberationSession:
        """
        Create a new deliberation session.

        Args:
            case_input: Parsed case information
            user_id: Optional user identifier

        Returns:
            New DeliberationSession
        """
        session_id = str(uuid4())

        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)
            db_session = await querier.create_council_session(
                CreateCouncilSessionParams(
                    id=session_id,
                    user_id=user_id,
                    status=SessionStatus.ACTIVE.value,
                    case_input=json.dumps(case_input.model_dump(mode="json")),
                    similar_cases=json.dumps([]),
                    legal_opinion=None,
                )
            )

        if not db_session:
            raise RuntimeError(f"Failed to create session {session_id}")

        logger.info(f"Created session: {session_id}")

        return _sqlc_session_to_schema(db_session, [])

    async def get_session(self, session_id: str) -> DeliberationSession | None:
        """Get a session by ID with all its messages."""
        async with self._db_engine.connect() as conn:
            querier = CouncilQuerier(conn)

            # Get session
            db_session = await querier.get_council_session(id=session_id)
            if not db_session:
                return None

            # Get messages
            messages = [
                msg
                async for msg in querier.get_council_session_with_messages(
                    session_id=session_id
                )
            ]

        return _sqlc_session_to_schema(db_session, messages)

    async def update_session(self, session: DeliberationSession) -> None:
        """Update a session in the database."""
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)
            await querier.update_council_session(
                UpdateCouncilSessionParams(
                    id=session.id,
                    status=session.status.value,
                    case_input=json.dumps(session.case_input.model_dump(mode="json")),
                    similar_cases=json.dumps(
                        [sc.model_dump(mode="json") for sc in session.similar_cases]
                    ),
                    legal_opinion=(
                        json.dumps(session.legal_opinion)
                        if session.legal_opinion is not None
                        else None
                    ),
                    concluded_at=session.concluded_at,
                )
            )
        logger.debug(f"Updated session: {session.id}")

    async def add_message(
        self,
        session_id: str,
        message: DeliberationMessage,
    ) -> DeliberationSession | None:
        """Add a message to a session.

        Uses atomic sequence number assignment with row-level locking to prevent
        race conditions when multiple requests add messages concurrently.
        """
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)

            # Lock session row to prevent race conditions (acts as mutex)
            locked_id = await querier.lock_council_session(id=session_id)
            if locked_id is None:
                return None

            # Get next sequence number (safe because session is locked)
            seq = await querier.get_latest_message_sequence(session_id=session_id)
            next_sequence = (seq if seq is not None else -1) + 1

            # Create message
            await querier.create_council_message(
                CreateCouncilMessageParams(
                    id=message.id,
                    session_id=session_id,
                    sender=json.dumps(_sender_to_dict(message.sender)),
                    content=message.content,
                    intent=message.intent,
                    cited_cases=json.dumps(message.cited_cases or []),
                    cited_laws=json.dumps(message.cited_laws or []),
                    sequence_number=next_sequence,
                )
            )

            # Update session timestamp
            await querier.touch_council_session(id=session_id)

            # Fetch session and messages WITHIN the transaction
            db_session = await querier.get_council_session(id=session_id)
            if db_session is None:
                return None

            db_messages = [
                msg
                async for msg in querier.get_council_session_with_messages(
                    session_id=session_id
                )
            ]

            return _sqlc_session_to_schema(db_session, db_messages)

    async def add_messages(
        self,
        session_id: str,
        messages: list[DeliberationMessage],
    ) -> DeliberationSession | None:
        """Add multiple messages to a session.

        Uses atomic sequence number assignment with row-level locking to prevent
        race conditions when multiple requests add messages concurrently.
        """
        if not messages:
            return await self.get_session(session_id)

        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)

            # Lock session row to prevent race conditions (acts as mutex)
            locked_id = await querier.lock_council_session(id=session_id)
            if locked_id is None:
                return None

            # Get base sequence number (safe because session is locked)
            seq = await querier.get_latest_message_sequence(session_id=session_id)
            base_sequence = (seq if seq is not None else -1) + 1

            # Batch insert all messages using executemany for efficiency
            # This avoids N+1 queries by sending all inserts in a single round-trip
            message_params = [
                {
                    "p1": message.id,
                    "p2": session_id,
                    "p3": json.dumps(_sender_to_dict(message.sender)),
                    "p4": message.content,
                    "p5": message.intent,
                    "p6": json.dumps(message.cited_cases or []),
                    "p7": json.dumps(message.cited_laws or []),
                    "p8": base_sequence + i,
                }
                for i, message in enumerate(messages)
            ]

            insert_sql = sqlalchemy.text("""
                INSERT INTO council_v1.deliberation_messages (
                    id, session_id, sender, content, intent,
                    cited_cases, cited_laws, sequence_number, timestamp
                ) VALUES (
                    :p1, :p2, :p3, :p4, :p5, :p6, :p7, :p8, NOW()
                )
            """)

            await conn.execute(insert_sql, message_params)

            # Update session timestamp
            await querier.touch_council_session(id=session_id)

            # Fetch session and messages WITHIN the transaction
            db_session = await querier.get_council_session(id=session_id)
            if db_session is None:
                return None

            db_messages = [
                msg
                async for msg in querier.get_council_session_with_messages(
                    session_id=session_id
                )
            ]

            return _sqlc_session_to_schema(db_session, db_messages)

    async def add_message_with_responses(
        self,
        session_id: str,
        user_message: DeliberationMessage,
        agent_responses: list[DeliberationMessage],
    ) -> DeliberationSession | None:
        """Add user message and agent responses atomically in a single transaction.

        This ensures that if persisting agent responses fails, the user message
        is not orphaned in the database. Both are committed together or neither.

        Args:
            session_id: The session to add messages to
            user_message: The user's message
            agent_responses: List of agent response messages

        Returns:
            Updated session or None if session not found
        """
        all_messages = [user_message] + agent_responses
        return await self.add_messages(session_id, all_messages)

    async def set_similar_cases(
        self,
        session_id: str,
        similar_cases: list[SimilarCase],
    ) -> None:
        """Set similar cases for a session."""
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)
            await querier.update_council_session_similar_cases(
                id=session_id,
                similar_cases=json.dumps(
                    [sc.model_dump(mode="json") for sc in similar_cases]
                ),
            )

    async def conclude_session(self, session_id: str) -> DeliberationSession | None:
        """Mark a session as concluded."""
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)
            db_session = await querier.conclude_council_session(id=session_id)

            if not db_session:
                return None

            # Fetch messages WITHIN the transaction
            db_messages = [
                msg
                async for msg in querier.get_council_session_with_messages(
                    session_id=session_id
                )
            ]

            return _sqlc_session_to_schema(db_session, db_messages)

    async def list_sessions(
        self,
        user_id: str | None = None,
        status: SessionStatus | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> list[DeliberationSession]:
        """List sessions with optional filtering."""
        async with self._db_engine.connect() as conn:
            querier = CouncilQuerier(conn)

            # Get sessions
            db_sessions = [
                s
                async for s in querier.list_council_sessions(
                    user_id=user_id,
                    status=status.value if status else None,
                    limit_val=limit,
                    offset_val=offset,
                )
            ]

            if not db_sessions:
                return []

            # Collect all session IDs for bulk message fetch
            session_ids = [s.id for s in db_sessions]

            # Bulk fetch messages for all sessions (reusing same connection)
            all_messages = [
                msg
                async for msg in querier.get_messages_for_sessions(
                    session_ids=session_ids
                )
            ]

        # Group messages by session_id (outside connection scope)
        messages_by_session: dict[str, list[CouncilV1DeliberationMessage]] = {}
        for msg in all_messages:
            if msg.session_id not in messages_by_session:
                messages_by_session[msg.session_id] = []
            messages_by_session[msg.session_id].append(msg)

        # Convert to schemas
        return [
            _sqlc_session_to_schema(
                db_session, messages_by_session.get(db_session.id, [])
            )
            for db_session in db_sessions
        ]

    async def count_sessions(
        self,
        user_id: str | None = None,
        status: SessionStatus | None = None,
    ) -> int:
        """Count sessions with optional filtering."""
        async with self._db_engine.connect() as conn:
            querier = CouncilQuerier(conn)
            count = await querier.count_council_sessions(
                user_id=user_id,
                status=status.value if status else None,
            )
        return count or 0

    async def delete_session(self, session_id: str) -> bool:
        """Delete a session and all its messages."""
        async with self._db_engine.begin() as conn:
            querier = CouncilQuerier(conn)

            # Check if session exists
            db_session = await querier.get_council_session(id=session_id)
            if not db_session:
                return False

            # Delete messages first
            await querier.delete_messages_for_session(session_id=session_id)

            # Delete session
            await querier.delete_council_session(id=session_id)

        logger.info(f"Deleted session: {session_id}")
        return True


# =============================================================================
# Case Database (SQLC-based)
# =============================================================================


class CaseDatabase:
    """
    Database operations for case data and similarity search.

    Uses the existing llm_extractions table with pgvector embeddings.
    """

    def __init__(self, db_engine: AsyncEngine):
        """
        Initialize the case database.

        Args:
            db_engine: SQLAlchemy async engine
        """
        self.db_engine = db_engine
        self.embedding_service = get_council_embedding_service()
        logger.info("Case database initialized")

    async def find_similar_cases(
        self,
        case_input: CaseInput,
        limit: int = 5,
    ) -> list[SimilarCase]:
        """
        Find similar cases using semantic search.

        Args:
            case_input: Parsed case information
            limit: Maximum number of similar cases

        Returns:
            List of similar cases with similarity scores
        """
        # Build search text from case input
        search_text = self.embedding_service.build_search_text(
            case_input.parsed_case.model_dump()
        )

        if not search_text:
            logger.warning("No search text generated from case input")
            return []

        # Generate query embedding
        query_embedding = await self.embedding_service.generate_query_embedding(
            search_text
        )

        if not query_embedding:
            logger.warning("Failed to generate query embedding")
            return []

        # Search using SQLC querier
        query_vector_str = f"[{','.join(str(x) for x in query_embedding)}]"

        async with self.db_engine.connect() as conn:
            querier = ExtractionQuerier(conn)
            rows = [
                row
                async for row in querier.find_similar_cases_by_embedding(
                    dollar_1=query_vector_str, limit=limit
                )
            ]

        similar_cases = []
        for row in rows:
            case = self._sqlc_row_to_similar_case(row)
            if case:
                similar_cases.append(case)

        logger.info(f"Found {len(similar_cases)} similar cases")
        return similar_cases

    def _sqlc_row_to_similar_case(
        self, row: FindSimilarCasesByEmbeddingRow
    ) -> SimilarCase | None:
        """Convert a SQLC row to SimilarCase."""
        try:
            extraction_result = row.extraction_result or {}

            # Extract case number from court info (primary location)
            case_number = "Unknown"
            court = extraction_result.get("court", {}) or {}
            if court.get("verdict_number"):
                case_number = court["verdict_number"]
            elif court.get("case_register_number"):
                case_number = court["case_register_number"]
            else:
                # Fallback to case_metadata
                case_meta = extraction_result.get("case_metadata", {}) or {}
                if case_meta.get("case_number"):
                    case_number = case_meta["case_number"]

            # Extract verdict info
            verdict = extraction_result.get("verdict", {}) or {}
            verdict_result = verdict.get("result", "unknown")
            verdict_summary = f"Verdict: {verdict_result}"

            # Extract sentence months
            sentences = verdict.get("sentences", {}) or {}
            imprisonment = sentences.get("imprisonment", {}) or {}
            sentence_months = 0
            if imprisonment.get("duration_months"):
                sentence_months = imprisonment["duration_months"]
            elif imprisonment.get("duration_years"):
                sentence_months = imprisonment["duration_years"] * 12

            # Build similarity reason with crime category and defendant info
            case_meta = extraction_result.get("case_metadata", {}) or {}
            crime_category = (
                case_meta.get("crime_category")
                or extraction_result.get("crime_category")
                or "Unknown"
            )
            defendant = extraction_result.get("defendant", {}) or {}
            defendant_name = defendant.get("name", "")
            if defendant_name:
                similarity_reason = f"{crime_category} case involving {defendant_name}"
            else:
                similarity_reason = f"Similar {crime_category} case"

            return SimilarCase(
                case_id=row.extraction_id,
                case_number=case_number,
                similarity_score=float(row.similarity),
                similarity_reason=similarity_reason,
                verdict_summary=verdict_summary,
                sentence_months=sentence_months,
            )
        except (KeyError, TypeError, ValueError) as e:
            logger.error(f"Failed to parse similar case - malformed data: {e}")
            return None

    def row_to_case_record(self, row: Any) -> CaseRecord | None:
        """Convert any SQLC row with extraction_id and extraction_result to CaseRecord.

        This is a generic converter that works with any row type that has:
        - extraction_id: str
        - extraction_result: dict | None
        - summary_en: str | None (optional)
        - summary_id: str | None (optional)

        Use this for rows from GetAllCases, GetCasesByTypePattern, or similar queries.
        """
        try:
            data = _extract_common_case_data(row.extraction_result)

            return CaseRecord(
                id=row.extraction_id,
                case_number=data["case_number"],
                case_type=data["case_type"],
                court_name=(
                    data["court"].get("court_name")
                    or data["case_meta"].get("court_name")
                ),
                court_type=(
                    data["court"].get("court_level")
                    or data["case_meta"].get("court_type")
                ),
                decision_date=data["case_meta"].get("decision_date"),
                defendant_name=data["defendant"].get("name"),
                defendant_age=data["defendant"].get("age"),
                defendant_first_offender=None,
                indictment=data["result"].get("indictment"),
                narcotics_details=data["result"].get("narcotics"),
                corruption_details=data["result"].get("state_loss"),
                legal_facts=data["result"].get("legal_facts"),
                verdict=data["verdict"],
                legal_basis=self._extract_legal_basis(data["result"]),
                extraction_result=data["result"],
                summary_en=getattr(row, "summary_en", None),
                summary_id=getattr(row, "summary_id", None),
            )
        except (KeyError, TypeError, ValueError, AttributeError) as e:
            logger.error(f"Failed to parse case record - malformed data: {e}")
            return None

    async def get_case(self, extraction_id: str) -> CaseRecord | None:
        """
        Get a case record by extraction ID.

        Args:
            extraction_id: ID of the extraction

        Returns:
            CaseRecord or None if not found
        """
        async with self.db_engine.connect() as conn:
            querier = ExtractionQuerier(conn)
            row = await querier.get_llm_extraction_by_id(extraction_id=extraction_id)

        if not row:
            return None

        return self.row_to_case_record(row)

    async def search_cases(
        self,
        query: str,
        limit: int = 10,
        semantic_search: bool = True,
        filters: dict[str, Any] | None = None,
    ) -> list[CaseRecord]:
        """
        Search for cases by query.

        Args:
            query: Search query
            limit: Maximum results
            semantic_search: Whether to use semantic search
            filters: Optional structured filters

        Returns:
            List of matching case records
        """
        if semantic_search:
            return await self._semantic_search(query, limit, filters)
        else:
            return await self._text_search(query, limit, filters)

    async def _semantic_search(
        self,
        query: str,
        limit: int,
        filters: dict[str, Any] | None = None,
    ) -> list[CaseRecord]:
        """Perform semantic search using embeddings."""
        # Generate query embedding
        query_embedding = await self.embedding_service.generate_query_embedding(query)

        if not query_embedding:
            logger.warning("Failed to generate query embedding for search")
            return []

        query_vector_str = f"[{','.join(str(x) for x in query_embedding)}]"

        async with self.db_engine.connect() as conn:
            querier = ExtractionQuerier(conn)

            if filters and filters.get("case_type"):
                # Single bilingual ILIKE-ANY query: the SQL accepts an array
                # of patterns so a logical case type ("corruption") can match
                # both Indonesian and English crime-category storage in one
                # round trip without N+1 queries or in-memory dedup.
                patterns = _case_type_filter_patterns(filters["case_type"])
                stream = querier.find_similar_cases_by_embedding_with_filter(
                    dollar_1=query_vector_str,
                    limit=limit,
                    dollar_3=patterns,
                )
                rows = [row async for row in stream]
            else:
                # Use unfiltered query
                rows = [
                    row
                    async for row in querier.find_similar_cases_by_embedding(
                        dollar_1=query_vector_str, limit=limit
                    )
                ]

        return [record for row in rows if (record := self.row_to_case_record(row))]

    async def _text_search(
        self,
        query: str,
        limit: int,
        filters: dict[str, Any] | None = None,
    ) -> list[CaseRecord]:
        """Perform text-based search on summaries."""
        async with self.db_engine.connect() as conn:
            querier = ExtractionQuerier(conn)
            rows = [
                row
                async for row in querier.text_search_cases(
                    summary_id=f"%{query}%", limit=limit
                )
            ]

        return [record for row in rows if (record := self.row_to_case_record(row))]

    def _extract_legal_basis(self, result: dict[str, Any]) -> list[str]:
        """Extract legal basis from extraction result."""
        legal_basis = []
        indictment = result.get("indictment", {}) or {}
        cited_articles = indictment.get("cited_articles", []) or []

        for article in cited_articles[:10]:
            if article and article.get("full_citation"):
                legal_basis.append(article["full_citation"])
            elif article and article.get("article"):
                legal_basis.append(article["article"])

        return legal_basis


# =============================================================================
# Singletons
# =============================================================================

_session_store: SessionStore | None = None


def init_session_store(db_engine: AsyncEngine) -> SessionStore:
    """
    Initialize the session store singleton with a database engine.

    Must be called once at application startup before using get_session_store().

    Args:
        db_engine: SQLAlchemy async engine for database operations

    Returns:
        The initialized SessionStore instance
    """
    global _session_store
    _session_store = SessionStore(db_engine)
    logger.info("Session store initialized with database engine")
    return _session_store


def get_session_store() -> SessionStore:
    """
    Get the session store singleton.

    Raises:
        RuntimeError: If init_session_store() hasn't been called yet
    """
    global _session_store
    if _session_store is None:
        raise RuntimeError(
            "Session store not initialized. Call init_session_store() first."
        )
    return _session_store
