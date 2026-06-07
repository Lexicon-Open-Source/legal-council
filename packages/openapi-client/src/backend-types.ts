export type paths = {
    "/v1/council/sessions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** List deliberation sessions */
        get: operations["listCouncilSessions"];
        put?: never;
        /**
         * Create new deliberation session
         * @description Creates a deliberation session from a case summary.
         *
         *     By default this endpoint returns JSON after the first initial judge
         *     message has been generated. When the request includes
         *     `Accept: text/event-stream`, the same creation flow is streamed as SSE:
         *     setup progress, session creation, first judge chunks, and a final
         *     completion event. The existing
         *     `/v1/council/deliberation/{session_id}/stream/initial` endpoint can then
         *     stream the remaining initial judges.
         */
        post: operations["createCouncilSession"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/sessions/{session_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get session details */
        get: operations["getCouncilSession"];
        put?: never;
        post?: never;
        /** Delete session */
        delete: operations["deleteCouncilSession"];
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/sessions/{session_id}/conclude": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Conclude deliberation session */
        post: operations["concludeCouncilSession"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/deliberation/{session_id}/message": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Send message to council */
        post: operations["sendCouncilMessage"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/deliberation/{session_id}/continue": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /** Continue deliberation */
        post: operations["continueCouncilDiscussion"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/deliberation/{session_id}/messages": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get deliberation messages */
        get: operations["getCouncilMessages"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/deliberation/{session_id}/opinion": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get generated opinion */
        get: operations["getCouncilOpinion"];
        put?: never;
        /** Generate legal opinion */
        post: operations["generateCouncilOpinion"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/deliberation/{session_id}/stream/initial": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Stream remaining initial opinions from judges
         * @description Session creation generates 1 random judge's opinion. This endpoint
         *     streams opinions from the remaining judges to complete the initial
         *     deliberation round.
         */
        post: operations["streamCouncilInitial"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/deliberation/{session_id}/stream/message": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Stream message response
         * @description Send a message and stream agent responses in real-time.
         *     The orchestrator determines which agent(s) should respond based on
         *     target_agent, message intent, and conversation balance.
         */
        post: operations["streamCouncilMessage"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/deliberation/{session_id}/stream/continue": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Stream continued deliberation
         * @description Continue the judicial discussion with streaming responses.
         *     Allows judges to deliberate amongst themselves in real-time.
         */
        post: operations["streamCouncilContinue"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/deliberation/{session_id}/download/pdf": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Download deliberation as PDF */
        get: operations["downloadCouncilPDF"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/cases/search": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Search similar cases */
        get: operations["searchCouncilCasesGet"];
        put?: never;
        /** Search similar cases */
        post: operations["searchCouncilCases"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/cases/by-type/{case_type}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get cases by type */
        get: operations["getCouncilCasesByType"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/cases/{case_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get case details */
        get: operations["getCouncilCase"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/v1/council/cases/statistics": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get case statistics */
        get: operations["getCouncilCaseStatistics"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/health": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Liveness probe
         * @description Check if the service is alive and responding to requests
         */
        get: operations["getHealth"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/ready": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Readiness probe
         * @description Check if the service is ready to accept traffic (database and Redis connections healthy)
         */
        get: operations["getReady"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
};
export type webhooks = Record<string, never>;
export type components = {
    schemas: {
        /**
         * @description Identifiers for the judicial AI agents
         * @enum {string}
         */
        AgentId: "strict" | "humanist" | "historian";
        /** @description An agent's position on a specific issue in the deliberation */
        AgentPosition: {
            /** @description The deliberation issue being discussed */
            issue: string;
            stance: components["schemas"]["PositionStance"];
            /** @description 1-2 sentence summary of the agent's reasoning */
            reasoning_summary: string;
            /** @description The round number when this position was stated */
            round_stated: number;
        };
        AgentSender: {
            /**
             * @description discriminator enum property added by openapi-typescript
             * @enum {string}
             */
            type: "agent";
            agent_id: components["schemas"]["AgentId"];
        };
        /** @description Tracks agent positions and agreement across deliberation issues */
        AgreementMap: {
            /**
             * @description Map of issue_key to agent positions (agent_id -> AgentPosition)
             * @default {}
             */
            issues: {
                [key: string]: {
                    [key: string]: components["schemas"]["AgentPosition"];
                };
            };
            /** @default 0 */
            round_count: number;
            /** @default 0 */
            regression_count: number;
            /**
             * Format: float
             * @description Proportion of issues with majority agreement (0.0-1.0)
             * @default 0
             */
            convergence_score: number;
            /**
             * @description Round number of the last convergence check
             * @default 0
             */
            last_convergence_check: number;
        };
        /** @description An applicable law reference */
        ApplicableLaw: {
            /** @description Reference to the law (e.g., Article 2 UU 31/1999) */
            law_reference: string;
            /** @description Description of the law */
            description: string;
            /** @description How this law applies to the case */
            how_it_applies: string;
        };
        /** @description A single argument point in the legal opinion */
        ArgumentPoint: {
            /**
             * @description Single bullet-point legal argument. ONE concise sentence stating
             *     only the substantive legal point — no greetings, honorifics
             *     ("Yang Mulia"), speaker self-references ("Saya berpendapat"), or
             *     introductory framing. Suitable for direct rendering as a list
             *     item. Maximum ~40 words.
             * @example Terdakwa terbukti merugikan keuangan negara sebesar Rp 5 miliar, memenuhi unsur Pasal 2 UU Tipikor.
             */
            argument: string;
            source_agent: components["schemas"]["AgentId"];
            /** @description Cases supporting this argument */
            supporting_cases?: string[];
            /** @description Argument strength (strong, moderate, weak) */
            strength: string;
        };
        /** @description Complete case input with raw and parsed data */
        CaseInput: {
            input_type: components["schemas"]["InputType"];
            raw_input: string;
            parsed_case: components["schemas"]["ParsedCaseInput"];
        };
        /** @description A case record from the database */
        CaseRecord: {
            id?: string;
            case_number?: string | null;
            case_type?: components["schemas"]["CouncilCaseType"];
            court_name?: string | null;
            court_type?: string | null;
            decision_date?: string | null;
            defendant_name?: string | null;
            defendant_age?: number | null;
            defendant_first_offender?: boolean | null;
            indictment?: Record<string, never> | null;
            narcotics_details?: Record<string, never> | null;
            corruption_details?: Record<string, never> | null;
            legal_facts?: Record<string, never> | null;
            verdict?: Record<string, never> | null;
            legal_basis?: string[] | null;
            /** @default false */
            is_landmark_case: boolean;
            extraction_result?: Record<string, never> | null;
            summary_en?: string | null;
            summary_id?: string | null;
        };
        /** @description Response for case statistics */
        CaseStatisticsResponse: {
            total_cases: number;
            sentence_distribution: Record<string, never>;
            verdict_distribution: Record<string, never>;
        };
        ChartItem: {
            label: string;
            value: number;
        };
        /** @description A precedent case cited in the opinion */
        CitedPrecedent: {
            /** @description Unique identifier of the precedent case */
            case_id: string;
            /** @description Official case number */
            case_number: string;
            /** @description Why this case is relevant */
            relevance: string;
            /** @description Summary of the verdict */
            verdict_summary: string;
            /** @description How this precedent applies to the current case */
            how_it_applies: string;
        };
        ContinueDiscussionRequest: {
            /**
             * @description Number of discussion rounds (each round = all judges respond)
             * @default 1
             */
            num_rounds: number;
        };
        ContinueDiscussionResponse: {
            new_messages: components["schemas"]["DeliberationMessage"][];
            total_messages: number;
        };
        /** @description Details specific to corruption cases */
        CorruptionDetails: {
            /** Format: float */
            state_loss_idr: number;
            position?: string | null;
        };
        /**
         * @description Types of legal cases
         * @enum {string}
         */
        CouncilCaseType: "narcotics" | "corruption" | "general_criminal" | "other";
        /** @description Profile of the defendant in a case */
        CouncilDefendantProfile: {
            /** @default true */
            is_first_offender: boolean;
            age?: number | null;
            occupation?: string | null;
        };
        /** @description A similar case found via semantic search */
        CouncilSimilarCase: {
            case_id: string;
            case_number: string;
            /** Format: float */
            similarity_score: number;
            similarity_reason: string;
            verdict_summary: string;
            sentence_months: number;
        };
        CreateSessionRequest: {
            /** @description Summary of the case for deliberation */
            case_summary: string;
            case_type?: components["schemas"]["CouncilCaseType"];
            structured_data?: components["schemas"]["StructuredCaseData"];
            input_type?: components["schemas"]["InputType"];
        };
        /** @description Response after creating a session */
        CreateSessionResponse: {
            session_id: string;
            parsed_case: components["schemas"]["ParsedCaseInput"];
            similar_cases: components["schemas"]["CouncilSimilarCase"][];
            initial_message?: components["schemas"]["DeliberationMessage"];
        };
        /** @description Data payload for streaming session creation events (SSE) */
        CreateSessionStreamEventData: {
            event_type: components["schemas"]["CreateSessionStreamEventType"];
            /** @description Progress status for setup events */
            status?: string | null;
            /** @description Session identifier once the session has been created */
            session_id?: string | null;
            parsed_case?: components["schemas"]["ParsedCaseInput"];
            similar_cases?: components["schemas"]["CouncilSimilarCase"][] | null;
            agent_id?: components["schemas"]["AgentId"];
            /** @description Event content, chunk text, or error text */
            content?: string | null;
            /** @description Message identifier for agent stream events */
            message_id?: string | null;
            /** @description Full message content on agent completion */
            full_content?: string | null;
            initial_message?: components["schemas"]["DeliberationMessage"];
            /** @description HTTP-like status code for terminal error events */
            status_code?: number | null;
        };
        /**
         * @description Event types emitted while creating a deliberation session
         * @enum {string}
         */
        CreateSessionStreamEventType: "status" | "session_created" | "agent_start" | "chunk" | "agent_complete" | "session_complete" | "error";
        /** @description A message in a deliberation session */
        DeliberationMessage: {
            id: string;
            session_id: string;
            sender: components["schemas"]["MessageSender"];
            content: string;
            intent?: string | null;
            /** @default [] */
            cited_cases: string[];
            /** @default [] */
            cited_laws: string[];
            /** Format: date-time */
            timestamp?: string | null;
        };
        /**
         * @description Current phase of a deliberation session
         * @enum {string}
         */
        DeliberationPhase: "legacy" | "opening" | "debate" | "convergence" | "summary";
        /** @description A deliberation session */
        DeliberationSession: {
            id: string;
            user_id?: string | null;
            status: components["schemas"]["SessionStatus"];
            current_phase?: components["schemas"]["DeliberationPhase"];
            phase_metadata?: components["schemas"]["PhaseMetadata"];
            case_input: components["schemas"]["CaseInput"];
            /** @default [] */
            similar_cases: components["schemas"]["CouncilSimilarCase"][];
            /** @default [] */
            messages: components["schemas"]["DeliberationMessage"][];
            legal_opinion?: Record<string, never> | null;
            /** @description Structured deliberation summary (populated in summary phase) */
            structured_summary?: Record<string, never> | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
            /** Format: date-time */
            concluded_at?: string | null;
        };
        Error: {
            error: string;
            status_code?: number;
        };
        FilterOption: {
            value: string;
            label: string;
            /** @description Optional - number of records with this value */
            count?: number | null;
        };
        /** @description Request to generate a legal opinion */
        GenerateOpinionRequest: {
            /** @default true */
            include_dissent: boolean;
        };
        /** @description Response containing the generated legal opinion */
        GenerateOpinionResponse: {
            opinion: components["schemas"]["LegalOpinionDraft"];
        };
        /** @description Response for getting a single case */
        GetCaseResponse: {
            case: components["schemas"]["CaseRecord"];
        };
        /** @description Response for getting messages */
        GetMessagesResponse: {
            messages: components["schemas"]["DeliberationMessage"][];
        };
        /** @description Response for getting a session */
        GetSessionResponse: {
            session: components["schemas"]["DeliberationSession"];
        };
        /**
         * @description Type of case input
         * @enum {string}
         */
        InputType: "text_summary" | "extraction_id";
        /** @description Collected legal arguments from the deliberation */
        LegalArguments: {
            /** @description Arguments supporting conviction */
            for_conviction?: components["schemas"]["ArgumentPoint"][];
            /** @description Arguments supporting leniency */
            for_leniency?: components["schemas"]["ArgumentPoint"][];
            /** @description Arguments supporting severity */
            for_severity?: components["schemas"]["ArgumentPoint"][];
        };
        /** @description Generated legal opinion from a deliberation session */
        LegalOpinionDraft: {
            /** @description Session this opinion belongs to */
            session_id: string;
            /**
             * Format: date-time
             * @description When the opinion was generated
             */
            generated_at: string;
            /** @description Summary of the case */
            case_summary: string;
            verdict_recommendation: components["schemas"]["VerdictRecommendation"];
            sentence_recommendation: components["schemas"]["SentenceRecommendation"];
            legal_arguments: components["schemas"]["LegalArguments"];
            /** @description Precedent cases cited in the opinion */
            cited_precedents?: components["schemas"]["CitedPrecedent"][];
            /** @description Laws applicable to the case */
            applicable_laws?: components["schemas"]["ApplicableLaw"][];
            /** @description Dissenting opinions from judges */
            dissenting_views?: string[];
        };
        /** @description Response for listing sessions */
        ListSessionsResponse: {
            sessions: components["schemas"]["DeliberationSession"][];
            pagination: {
                [key: string]: number;
            };
        };
        /**
         * @description Intent classification for user messages
         * @enum {string}
         */
        MessageIntent: "ask_opinion" | "request_comparison" | "challenge_view" | "seek_consensus" | "general_question" | "address_agent" | "introduce_evidence" | "request_summary" | "override_suggestion";
        /** @description Union type for message senders */
        MessageSender: components["schemas"]["UserSender"] | components["schemas"]["AgentSender"] | components["schemas"]["SystemSender"];
        /** @description Details specific to narcotics cases */
        NarcoticsDetails: {
            substance: string;
            /** Format: float */
            weight_grams: number;
            intent?: components["schemas"]["NarcoticsIntent"];
        };
        /**
         * @description Intent classification for narcotics cases
         * @enum {string}
         */
        NarcoticsIntent: "personal_use" | "distribution" | "unknown";
        PaginationMeta: {
            current_page: number;
            last_page: number;
            per_page: number;
            total: number;
        };
        /** @description Parsed and structured case information */
        ParsedCaseInput: {
            case_type: components["schemas"]["CouncilCaseType"];
            summary: string;
            defendant_profile?: components["schemas"]["CouncilDefendantProfile"];
            /** @default [] */
            key_facts: string[];
            /** @default [] */
            charges: string[];
            narcotics?: components["schemas"]["NarcoticsDetails"];
            corruption?: components["schemas"]["CorruptionDetails"];
        };
        /** @description Metadata tracking the deliberation phase state */
        PhaseMetadata: {
            agreement_map?: components["schemas"]["AgreementMap"];
            /** @default [] */
            phase_history: {
                phase?: string;
                /** Format: date-time */
                entered_at?: string;
                round?: number;
            }[];
        };
        /**
         * @description An agent's stance on a deliberation issue
         * @enum {string}
         */
        PositionStance: "agree" | "disagree" | "partial" | "no_position";
        /** @description Request for searching cases */
        SearchCasesRequest: {
            query: string;
            /** @default 10 */
            limit: number;
            /** @default true */
            semantic_search: boolean;
            filters?: components["schemas"]["StructuredCaseData"];
        };
        /** @description Response for case search */
        SearchCasesResponse: {
            cases: components["schemas"]["CaseRecord"][];
            total: number;
        };
        SendMessageRequest: {
            /** @description Message content to send to the council */
            content: string;
            /**
             * @description Target a specific agent or all agents
             * @enum {string|null}
             */
            target_agent?: "legalis" | "humanis" | "sejarawan" | "strict" | "humanist" | "historian" | "all" | null;
        };
        SendMessageResponse: {
            user_message: components["schemas"]["DeliberationMessage"];
            agent_responses: components["schemas"]["DeliberationMessage"][];
        };
        /**
         * @description Type of message sender
         * @enum {string}
         */
        SenderType: "user" | "agent" | "system";
        /** @description A range for sentencing recommendations */
        SentenceRange: {
            /** @description Minimum sentence value */
            minimum: number;
            /** @description Maximum sentence value */
            maximum: number;
            /** @description Recommended sentence value */
            recommended: number;
        };
        /** @description Recommendation for sentencing */
        SentenceRecommendation: {
            imprisonment_months: components["schemas"]["SentenceRange"];
            fine_idr: components["schemas"]["SentenceRange"];
            /** @description Additional penalties recommended */
            additional_penalties?: string[];
        };
        /**
         * @description Status of a deliberation session
         * @enum {string}
         */
        SessionStatus: "active" | "concluded" | "archived";
        SimilarCase: {
            /** @description Case ULID */
            id?: string;
            /** @description Case title */
            title?: string;
            /** @description Case summary */
            summary?: string;
            /** @description Court decision */
            decision?: string;
            /**
             * Format: float
             * @description Semantic similarity score (0-1)
             */
            similarity_score?: number;
            /** @description Decision year */
            year?: number;
            /** @description Court name */
            court?: string;
        };
        StreamContinueRequest: {
            /**
             * @description Number of discussion rounds (each round = all judges respond)
             * @default 1
             */
            num_rounds: number;
        };
        /** @description Data payload for streaming events (SSE) */
        StreamEventData: {
            event_type?: components["schemas"]["StreamEventType"];
            agent_id?: components["schemas"]["AgentId"];
            /** @description Event content (chunk text or message) */
            content?: string;
            /** @description Message identifier */
            message_id?: string | null;
            /** @description Full message content (only on agent_complete) */
            full_content?: string | null;
        };
        /**
         * @description Types of streaming events
         * @enum {string}
         */
        StreamEventType: "agent_start" | "chunk" | "agent_complete" | "agent_error" | "user_message" | "deliberation_complete" | "phase_transition" | "convergence_suggestion" | "summary_ready";
        StreamMessageRequest: {
            /** @description Message content to send */
            content: string;
            /**
             * @description Target a specific agent or all agents
             * @enum {string|null}
             */
            target_agent?: "legalis" | "humanis" | "sejarawan" | "strict" | "humanist" | "historian" | "all" | null;
        };
        /** @description Optional structured data that can be provided with case input */
        StructuredCaseData: {
            case_type?: components["schemas"]["CouncilCaseType"];
            defendant_age?: number | null;
            defendant_first_offender?: boolean | null;
            substance_type?: string | null;
            /** Format: float */
            weight_grams?: number | null;
            /** Format: float */
            state_loss_idr?: number | null;
        };
        SystemSender: {
            /**
             * @description discriminator enum property added by openapi-typescript
             * @enum {string}
             */
            type: "system";
        };
        UserSender: {
            /**
             * @description discriminator enum property added by openapi-typescript
             * @enum {string}
             */
            type: "user";
        };
        /**
         * @description Possible verdict decisions
         * @enum {string}
         */
        VerdictDecision: "guilty" | "not_guilty" | "acquitted";
        /** @description Recommendation for the verdict */
        VerdictRecommendation: {
            decision: components["schemas"]["VerdictDecision"];
            /** @description Confidence level (high, medium, low) */
            confidence: string;
            /** @description Reasoning behind the recommendation */
            reasoning: string;
        };
        YearRange: {
            min: number;
            max: number;
        };
    };
    responses: never;
    parameters: never;
    requestBodies: never;
    headers: never;
    pathItems: never;
};
export type $defs = Record<string, never>;
export interface operations {
    listCouncilSessions: {
        parameters: {
            query?: {
                /**
                 * @description Filter by session status
                 * @example active
                 */
                status?: "active" | "concluded" | "archived";
                /** @example 20 */
                limit?: number;
                /** @example 0 */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Sessions list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "sessions": [
                     *         {
                     *           "id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "status": "active",
                     *           "case_input": {
                     *             "input_type": "text_summary",
                     *             "raw_input": "Terdakwa Budi Santoso...",
                     *             "parsed_case": {
                     *               "case_type": "corruption",
                     *               "summary": "Kasus korupsi proyek pembangunan jalan"
                     *             }
                     *           },
                     *           "similar_cases": [],
                     *           "messages": [],
                     *           "created_at": "2024-03-15T10:30:00Z",
                     *           "updated_at": "2024-03-15T10:30:00Z"
                     *         },
                     *         {
                     *           "id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHJ",
                     *           "status": "concluded",
                     *           "case_input": {
                     *             "input_type": "text_summary",
                     *             "raw_input": "Terdakwa Ahmad Hidayat...",
                     *             "parsed_case": {
                     *               "case_type": "narcotics",
                     *               "summary": "Kasus kepemilikan narkotika jenis sabu"
                     *             }
                     *           },
                     *           "similar_cases": [],
                     *           "messages": [],
                     *           "created_at": "2024-03-14T09:00:00Z",
                     *           "updated_at": "2024-03-14T15:30:00Z",
                     *           "concluded_at": "2024-03-14T15:30:00Z"
                     *         }
                     *       ],
                     *       "pagination": {
                     *         "limit": 20,
                     *         "offset": 0,
                     *         "total": 25
                     *       }
                     *     }
                     */
                    "application/json": components["schemas"]["ListSessionsResponse"];
                };
            };
        };
    };
    createCouncilSession: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                /**
                 * @example {
                 *       "case_summary": "Terdakwa Budi Santoso, PNS Golongan IV/a pada Dinas PUPR Kabupaten X, didakwa telah melakukan tindak pidana korupsi terkait proyek pembangunan jalan senilai Rp 15 miliar. Jaksa mendakwa terdakwa telah menerima suap sebesar Rp 500 juta dari kontraktor PT Maju Jaya untuk memenangkan tender proyek tersebut. Terdakwa merupakan pelaku pertama kali dengan masa kerja 20 tahun. Kerugian negara yang terbukti adalah Rp 2,5 miliar akibat mark-up harga dan kualitas material yang tidak sesuai spesifikasi.",
                 *       "case_type": "corruption",
                 *       "structured_data": {
                 *         "defendant_age": 52,
                 *         "defendant_first_offender": true,
                 *         "state_loss_idr": 2500000000
                 *       },
                 *       "input_type": "text_summary"
                 *     }
                 */
                "application/json": components["schemas"]["CreateSessionRequest"];
            };
        };
        responses: {
            /** @description Session created successfully */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *       "parsed_case": {
                     *         "case_type": "corruption",
                     *         "summary": "Kasus korupsi proyek pembangunan jalan senilai Rp 15 miliar",
                     *         "defendant_profile": {
                     *           "is_first_offender": true,
                     *           "age": 52,
                     *           "occupation": "PNS Golongan IV/a Dinas PUPR"
                     *         },
                     *         "key_facts": [
                     *           "Menerima suap Rp 500 juta dari kontraktor",
                     *           "Mark-up harga proyek",
                     *           "Kualitas material tidak sesuai spesifikasi"
                     *         ],
                     *         "charges": [
                     *           "Pasal 12 huruf a UU 31/1999 jo UU 20/2001",
                     *           "Pasal 3 UU 31/1999"
                     *         ],
                     *         "corruption": {
                     *           "state_loss_idr": 2500000000,
                     *           "position": "Kepala Dinas PUPR"
                     *         }
                     *       },
                     *       "similar_cases": [],
                     *       "initial_message": {
                     *         "id": "msg_001",
                     *         "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *         "sender": {
                     *           "type": "agent",
                     *           "agent_id": "strict"
                     *         },
                     *         "content": "Berdasarkan fakta hukum yang terungkap, terdakwa jelas telah melanggar Pasal 12 huruf a UU Tipikor...",
                     *         "cited_cases": [
                     *           "01HN6ABC123"
                     *         ],
                     *         "cited_laws": [
                     *           "Pasal 12 huruf a UU 31/1999"
                     *         ],
                     *         "timestamp": "2024-03-15T10:30:00Z"
                     *       }
                     *     }
                     */
                    "application/json": components["schemas"]["CreateSessionResponse"];
                    /**
                     * @example {
                     *       "event_type": "session_created",
                     *       "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *       "parsed_case": {
                     *         "case_type": "corruption",
                     *         "summary": "Kasus korupsi proyek pembangunan jalan senilai Rp 15 miliar"
                     *       },
                     *       "similar_cases": []
                     *     }
                     */
                    "text/event-stream": components["schemas"]["CreateSessionStreamEventData"];
                };
            };
            /** @description Invalid request */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "error": "case_summary must be at least 50 characters",
                     *       "status_code": 400
                     *     }
                     */
                    "application/json": components["schemas"]["Error"];
                };
            };
        };
    };
    getCouncilSession: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Session details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "session": {
                     *         "id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *         "status": "active",
                     *         "case_input": {
                     *           "input_type": "text_summary",
                     *           "raw_input": "Terdakwa Budi Santoso, PNS Golongan IV/a pada Dinas PUPR...",
                     *           "parsed_case": {
                     *             "case_type": "corruption",
                     *             "summary": "Kasus korupsi proyek pembangunan jalan senilai Rp 15 miliar",
                     *             "defendant_profile": {
                     *               "is_first_offender": true,
                     *               "age": 52,
                     *               "occupation": "PNS Golongan IV/a Dinas PUPR"
                     *             },
                     *             "key_facts": [
                     *               "Menerima suap Rp 500 juta dari kontraktor",
                     *               "Kerugian negara Rp 2,5 miliar"
                     *             ],
                     *             "charges": [
                     *               "Pasal 12 huruf a UU 31/1999"
                     *             ],
                     *             "corruption": {
                     *               "state_loss_idr": 2500000000,
                     *               "position": "Kepala Dinas PUPR"
                     *             }
                     *           }
                     *         },
                     *         "similar_cases": [
                     *           {
                     *             "case_id": "01HN6ABC123",
                     *             "case_number": "45/Pid.Sus-TPK/2023/PN.Jkt.Pst",
                     *             "similarity_score": 0.87,
                     *             "similarity_reason": "Kasus korupsi proyek infrastruktur dengan modus mark-up serupa",
                     *             "verdict_summary": "Terdakwa terbukti bersalah, divonis 6 tahun penjara",
                     *             "sentence_months": 72
                     *           }
                     *         ],
                     *         "messages": [
                     *           {
                     *             "id": "msg_001",
                     *             "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *             "sender": {
                     *               "type": "agent",
                     *               "agent_id": "strict"
                     *             },
                     *             "content": "Berdasarkan fakta hukum, terdakwa jelas melanggar Pasal 12 huruf a...",
                     *             "cited_cases": [
                     *               "01HN6ABC123"
                     *             ],
                     *             "cited_laws": [
                     *               "Pasal 12 huruf a UU 31/1999"
                     *             ],
                     *             "timestamp": "2024-03-15T10:30:00Z"
                     *           }
                     *         ],
                     *         "legal_opinion": null,
                     *         "created_at": "2024-03-15T10:30:00Z",
                     *         "updated_at": "2024-03-15T10:35:00Z"
                     *       }
                     *     }
                     */
                    "application/json": components["schemas"]["GetSessionResponse"];
                };
            };
            /** @description Session not found */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "error": "session not found",
                     *       "status_code": 404
                     *     }
                     */
                    "application/json": components["schemas"]["Error"];
                };
            };
        };
    };
    deleteCouncilSession: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Session deleted */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "message": "session deleted successfully"
                     *     }
                     */
                    "application/json": {
                        message?: string;
                    };
                };
            };
        };
    };
    concludeCouncilSession: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Session concluded */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "session": {
                     *         "id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *         "status": "concluded",
                     *         "case_input": {
                     *           "input_type": "text_summary",
                     *           "raw_input": "Terdakwa Budi Santoso...",
                     *           "parsed_case": {
                     *             "case_type": "corruption",
                     *             "summary": "Kasus korupsi proyek pembangunan jalan"
                     *           }
                     *         },
                     *         "similar_cases": [],
                     *         "messages": [],
                     *         "legal_opinion": null,
                     *         "created_at": "2024-03-15T10:30:00Z",
                     *         "updated_at": "2024-03-15T12:00:00Z",
                     *         "concluded_at": "2024-03-15T12:00:00Z"
                     *       }
                     *     }
                     */
                    "application/json": components["schemas"]["GetSessionResponse"];
                };
            };
        };
    };
    sendCouncilMessage: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                /**
                 * @example {
                 *       "content": "Bagaimana pendapat Hakim Humanis mengenai faktor-faktor yang meringankan terdakwa, mengingat ini adalah pelanggaran pertamanya?",
                 *       "target_agent": "humanis"
                 *     }
                 */
                "application/json": components["schemas"]["SendMessageRequest"];
            };
        };
        responses: {
            /** @description Message sent and response received */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "user_message": {
                     *         "id": "msg_002",
                     *         "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *         "sender": {
                     *           "type": "user"
                     *         },
                     *         "content": "Bagaimana pendapat Hakim Humanis mengenai faktor-faktor yang meringankan terdakwa?",
                     *         "intent": "ask_opinion",
                     *         "cited_cases": [],
                     *         "cited_laws": [],
                     *         "timestamp": "2024-03-15T10:35:00Z"
                     *       },
                     *       "agent_responses": [
                     *         {
                     *           "id": "msg_003",
                     *           "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "sender": {
                     *             "type": "agent",
                     *             "agent_id": "humanist"
                     *           },
                     *           "content": "Terima kasih atas pertanyaannya. Dalam mempertimbangkan faktor-faktor yang meringankan, kita perlu melihat bahwa terdakwa adalah pelaku pertama kali dengan rekam jejak pelayanan publik selama 20 tahun. Hal ini menunjukkan bahwa tindakan korupsi ini mungkin bukan cerminan karakter sejatinya...",
                     *           "intent": null,
                     *           "cited_cases": [
                     *             "01HN6DEF456"
                     *           ],
                     *           "cited_laws": [
                     *             "Pasal 53 KUHP"
                     *           ],
                     *           "timestamp": "2024-03-15T10:35:15Z"
                     *         }
                     *       ]
                     *     }
                     */
                    "application/json": components["schemas"]["SendMessageResponse"];
                };
            };
        };
    };
    continueCouncilDiscussion: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                /**
                 * @example {
                 *       "num_rounds": 2
                 *     }
                 */
                "application/json": components["schemas"]["ContinueDiscussionRequest"];
            };
        };
        responses: {
            /** @description Deliberation continued */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "new_messages": [
                     *         {
                     *           "id": "msg_004",
                     *           "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "sender": {
                     *             "type": "agent",
                     *             "agent_id": "strict"
                     *           },
                     *           "content": "Saya tidak sependapat dengan Hakim Humanis. Meskipun terdakwa adalah pelaku pertama kali, kerugian negara yang ditimbulkan sangat besar...",
                     *           "cited_cases": [],
                     *           "cited_laws": [
                     *             "Pasal 2 ayat (1) UU 31/1999"
                     *           ],
                     *           "timestamp": "2024-03-15T10:40:00Z"
                     *         },
                     *         {
                     *           "id": "msg_005",
                     *           "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "sender": {
                     *             "type": "agent",
                     *             "agent_id": "historian"
                     *           },
                     *           "content": "Jika kita melihat preseden dalam kasus serupa, putusan MA No. 1261 K/Pid.Sus/2015 memberikan panduan bahwa...",
                     *           "cited_cases": [
                     *             "01HN6GHI789"
                     *           ],
                     *           "cited_laws": [],
                     *           "timestamp": "2024-03-15T10:40:30Z"
                     *         }
                     *       ],
                     *       "total_messages": 8
                     *     }
                     */
                    "application/json": components["schemas"]["ContinueDiscussionResponse"];
                };
            };
        };
    };
    getCouncilMessages: {
        parameters: {
            query?: {
                /** @example 50 */
                limit?: number;
                /** @example 0 */
                offset?: number;
            };
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Messages list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "messages": [
                     *         {
                     *           "id": "msg_001",
                     *           "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "sender": {
                     *             "type": "agent",
                     *             "agent_id": "strict"
                     *           },
                     *           "content": "Berdasarkan fakta hukum yang terungkap, terdakwa jelas telah melanggar Pasal 12 huruf a UU Tipikor...",
                     *           "cited_cases": [
                     *             "01HN6ABC123"
                     *           ],
                     *           "cited_laws": [
                     *             "Pasal 12 huruf a UU 31/1999"
                     *           ],
                     *           "timestamp": "2024-03-15T10:30:00Z"
                     *         },
                     *         {
                     *           "id": "msg_002",
                     *           "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "sender": {
                     *             "type": "user"
                     *           },
                     *           "content": "Bagaimana pendapat Hakim Humanis mengenai faktor yang meringankan?",
                     *           "intent": "ask_opinion",
                     *           "cited_cases": [],
                     *           "cited_laws": [],
                     *           "timestamp": "2024-03-15T10:35:00Z"
                     *         },
                     *         {
                     *           "id": "msg_003",
                     *           "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "sender": {
                     *             "type": "agent",
                     *             "agent_id": "humanist"
                     *           },
                     *           "content": "Dalam mempertimbangkan faktor meringankan, terdakwa adalah pelaku pertama kali...",
                     *           "cited_cases": [
                     *             "01HN6DEF456"
                     *           ],
                     *           "cited_laws": [
                     *             "Pasal 53 KUHP"
                     *           ],
                     *           "timestamp": "2024-03-15T10:35:15Z"
                     *         }
                     *       ]
                     *     }
                     */
                    "application/json": components["schemas"]["GetMessagesResponse"];
                };
            };
        };
    };
    getCouncilOpinion: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Opinion details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "opinion": {
                     *         "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *         "generated_at": "2024-03-15T11:00:00Z",
                     *         "case_summary": "Kasus korupsi proyek pembangunan jalan",
                     *         "verdict_recommendation": {
                     *           "decision": "guilty",
                     *           "confidence": "high",
                     *           "reasoning": "Terdakwa terbukti menerima suap dan menyalahgunakan wewenang"
                     *         },
                     *         "sentence_recommendation": {
                     *           "imprisonment_months": {
                     *             "minimum": 48,
                     *             "maximum": 72,
                     *             "recommended": 60
                     *           },
                     *           "fine_idr": {
                     *             "minimum": 200000000,
                     *             "maximum": 500000000,
                     *             "recommended": 300000000
                     *           },
                     *           "additional_penalties": [
                     *             "Pencabutan hak politik selama 3 tahun"
                     *           ]
                     *         },
                     *         "legal_arguments": {
                     *           "for_conviction": [],
                     *           "for_leniency": [],
                     *           "for_severity": []
                     *         },
                     *         "cited_precedents": [],
                     *         "applicable_laws": [],
                     *         "dissenting_views": []
                     *       }
                     *     }
                     */
                    "application/json": components["schemas"]["GenerateOpinionResponse"];
                };
            };
            /** @description Opinion not found */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "error": "opinion not found for session",
                     *       "status_code": 404
                     *     }
                     */
                    "application/json": components["schemas"]["Error"];
                };
            };
        };
    };
    generateCouncilOpinion: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody?: {
            content: {
                /**
                 * @example {
                 *       "include_dissent": true
                 *     }
                 */
                "application/json": components["schemas"]["GenerateOpinionRequest"];
            };
        };
        responses: {
            /** @description Opinion generated */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "opinion": {
                     *         "session_id": "sess_01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *         "generated_at": "2024-03-15T11:00:00Z",
                     *         "case_summary": "Kasus korupsi proyek pembangunan jalan dengan kerugian negara Rp 2,5 miliar",
                     *         "verdict_recommendation": {
                     *           "decision": "guilty",
                     *           "confidence": "high",
                     *           "reasoning": "Fakta hukum menunjukkan terdakwa terbukti menerima suap dan menyalahgunakan wewenang jabatan"
                     *         },
                     *         "sentence_recommendation": {
                     *           "imprisonment_months": {
                     *             "minimum": 48,
                     *             "maximum": 72,
                     *             "recommended": 60
                     *           },
                     *           "fine_idr": {
                     *             "minimum": 200000000,
                     *             "maximum": 500000000,
                     *             "recommended": 300000000
                     *           },
                     *           "additional_penalties": [
                     *             "Pencabutan hak politik selama 3 tahun",
                     *             "Membayar uang pengganti Rp 2,5 miliar"
                     *           ]
                     *         },
                     *         "legal_arguments": {
                     *           "for_conviction": [
                     *             {
                     *               "argument": "Bukti transfer dana dari kontraktor ke rekening terdakwa",
                     *               "source_agent": "strict",
                     *               "supporting_cases": [
                     *                 "01HN6ABC123"
                     *               ],
                     *               "strength": "strong"
                     *             }
                     *           ],
                     *           "for_leniency": [
                     *             {
                     *               "argument": "Terdakwa adalah pelaku pertama kali dengan rekam jejak baik",
                     *               "source_agent": "humanist",
                     *               "supporting_cases": [],
                     *               "strength": "moderate"
                     *             }
                     *           ],
                     *           "for_severity": [
                     *             {
                     *               "argument": "Kerugian negara sangat besar dan berdampak pada pembangunan infrastruktur",
                     *               "source_agent": "strict",
                     *               "supporting_cases": [
                     *                 "01HN6GHI789"
                     *               ],
                     *               "strength": "strong"
                     *             }
                     *           ]
                     *         },
                     *         "cited_precedents": [
                     *           {
                     *             "case_id": "01HN6ABC123",
                     *             "case_number": "45/Pid.Sus-TPK/2023/PN.Jkt.Pst",
                     *             "relevance": "Kasus korupsi proyek infrastruktur serupa",
                     *             "verdict_summary": "Terbukti bersalah, 6 tahun penjara",
                     *             "how_it_applies": "Modus operandi mark-up harga identik"
                     *           }
                     *         ],
                     *         "applicable_laws": [
                     *           {
                     *             "law_reference": "Pasal 12 huruf a UU 31/1999 jo UU 20/2001",
                     *             "description": "Penerimaan suap oleh penyelenggara negara",
                     *             "how_it_applies": "Terdakwa menerima Rp 500 juta untuk memenangkan tender"
                     *           },
                     *           {
                     *             "law_reference": "Pasal 3 UU 31/1999",
                     *             "description": "Penyalahgunaan wewenang jabatan",
                     *             "how_it_applies": "Terdakwa menggunakan jabatan untuk mengatur pemenang tender"
                     *           }
                     *         ],
                     *         "dissenting_views": [
                     *           "Hakim Humanis berpendapat vonis sebaiknya di bawah 5 tahun mengingat terdakwa adalah pelaku pertama kali"
                     *         ]
                     *       }
                     *     }
                     */
                    "application/json": components["schemas"]["GenerateOpinionResponse"];
                };
            };
        };
    };
    streamCouncilInitial: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description SSE stream of deliberation */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "event_type": "agent_start",
                     *       "agent_id": "humanist"
                     *     }
                     */
                    "text/event-stream": components["schemas"]["StreamEventData"];
                };
            };
        };
    };
    streamCouncilMessage: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                /**
                 * @example {
                 *       "content": "Hakim Legalis, apa pendapat Anda tentang vonis yang tepat untuk kasus ini?",
                 *       "target_agent": "legalis"
                 *     }
                 */
                "application/json": components["schemas"]["StreamMessageRequest"];
            };
        };
        responses: {
            /** @description SSE stream of response */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "event_type": "user_message",
                     *       "message_id": "msg_004",
                     *       "content": "Hakim Strict, apa pendapat Anda..."
                     *     }
                     */
                    "text/event-stream": components["schemas"]["StreamEventData"];
                };
            };
        };
    };
    streamCouncilContinue: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                /**
                 * @example {
                 *       "num_rounds": 1
                 *     }
                 */
                "application/json": components["schemas"]["StreamContinueRequest"];
            };
        };
        responses: {
            /** @description SSE stream of deliberation */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "event_type": "agent_start",
                     *       "agent_id": "humanist"
                     *     }
                     */
                    "text/event-stream": components["schemas"]["StreamEventData"];
                };
            };
        };
    };
    downloadCouncilPDF: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example sess_01HN6VJKM4XPQW3B5RTCDEFGHN */
                session_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description PDF file */
            200: {
                headers: {
                    /** @example attachment; filename="deliberation_sess_01HN6VJKM4XPQW3B5RTCDEFGHN.pdf" */
                    "Content-Disposition"?: string;
                    [name: string]: unknown;
                };
                content: {
                    "application/pdf": string;
                };
            };
        };
    };
    searchCouncilCasesGet: {
        parameters: {
            query: {
                /** @example korupsi proyek infrastruktur */
                query: string;
                /** @example 5 */
                limit?: number;
                /** @example true */
                semantic?: boolean;
                /** @example corruption */
                case_type?: components["schemas"]["CouncilCaseType"];
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Similar cases */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "cases": [
                     *         {
                     *           "id": "01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "case_number": "45/Pid.Sus-TPK/2023/PN.Jkt.Pst",
                     *           "case_type": "corruption",
                     *           "court_name": "Pengadilan Tipikor Jakarta Pusat",
                     *           "defendant_name": "Budi Santoso",
                     *           "summary_id": "Kepala Dinas PUPR terbukti menerima suap dari kontraktor untuk memenangkan tender proyek jalan."
                     *         }
                     *       ],
                     *       "total": 1
                     *     }
                     */
                    "application/json": components["schemas"]["SearchCasesResponse"];
                };
            };
            /** @description Invalid search request */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "error": "Please choose a valid case type.",
                     *       "status_code": 400
                     *     }
                     */
                    "application/json": components["schemas"]["Error"];
                };
            };
        };
    };
    searchCouncilCases: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                /**
                 * @example {
                 *       "query": "kasus korupsi proyek infrastruktur jalan dengan mark-up harga oleh pejabat dinas PUPR",
                 *       "limit": 5,
                 *       "semantic_search": true
                 *     }
                 */
                "application/json": components["schemas"]["SearchCasesRequest"];
            };
        };
        responses: {
            /** @description Similar cases */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "cases": [
                     *         {
                     *           "id": "01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "case_number": "45/Pid.Sus-TPK/2023/PN.Jkt.Pst",
                     *           "case_type": "corruption",
                     *           "court_name": "Pengadilan Tipikor Jakarta Pusat",
                     *           "court_type": "Pengadilan Tindak Pidana Korupsi",
                     *           "decision_date": "2023-08-17",
                     *           "defendant_name": "Budi Santoso",
                     *           "defendant_age": 52,
                     *           "defendant_first_offender": true,
                     *           "corruption_details": {
                     *             "state_loss_idr": 3500000000,
                     *             "position": "Kepala Dinas PUPR"
                     *           },
                     *           "legal_basis": [
                     *             "Pasal 12 huruf a UU 31/1999 jo UU 20/2001"
                     *           ],
                     *           "is_landmark_case": false,
                     *           "summary_id": "Kepala Dinas PUPR terbukti menerima suap dari kontraktor untuk memenangkan tender proyek jalan."
                     *         }
                     *       ],
                     *       "total": 1
                     *     }
                     */
                    "application/json": components["schemas"]["SearchCasesResponse"];
                };
            };
        };
    };
    getCouncilCasesByType: {
        parameters: {
            query?: {
                /** @example 20 */
                limit?: number;
                /** @example 0 */
                offset?: number;
            };
            header?: never;
            path: {
                /** @example corruption */
                case_type: components["schemas"]["CouncilCaseType"];
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Cases by type */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "cases": [
                     *         {
                     *           "id": "01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *           "case_number": "45/Pid.Sus-TPK/2023/PN.Jkt.Pst",
                     *           "case_type": "corruption",
                     *           "court_name": "Pengadilan Tipikor Jakarta Pusat",
                     *           "defendant_name": "Budi Santoso",
                     *           "summary_id": "Kepala Dinas PUPR terbukti menerima suap dari kontraktor untuk memenangkan tender proyek jalan."
                     *         }
                     *       ],
                     *       "total": 1
                     *     }
                     */
                    "application/json": components["schemas"]["SearchCasesResponse"];
                };
            };
            /** @description Invalid case type */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "error": "Please choose a valid case type.",
                     *       "status_code": 400
                     *     }
                     */
                    "application/json": components["schemas"]["Error"];
                };
            };
        };
    };
    getCouncilCase: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @example 01HN6VJKM4XPQW3B5RTCDEFGHN */
                case_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Case details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "case": {
                     *         "id": "01HN6VJKM4XPQW3B5RTCDEFGHN",
                     *         "case_number": "45/Pid.Sus-TPK/2023/PN.Jkt.Pst",
                     *         "case_type": "corruption",
                     *         "court_name": "Pengadilan Tipikor Jakarta Pusat",
                     *         "court_type": "Pengadilan Tindak Pidana Korupsi",
                     *         "decision_date": "2023-08-17",
                     *         "defendant_name": "Budi Santoso",
                     *         "defendant_age": 52,
                     *         "defendant_first_offender": true,
                     *         "indictment": {
                     *           "articles": [
                     *             "Pasal 12 huruf a UU 31/1999 jo UU 20/2001"
                     *           ]
                     *         },
                     *         "corruption_details": {
                     *           "state_loss_idr": 3500000000,
                     *           "position": "Kepala Dinas PUPR"
                     *         },
                     *         "legal_facts": {
                     *           "summary": "Terdakwa menerima suap untuk memenangkan tender proyek jalan."
                     *         },
                     *         "verdict": {
                     *           "decision": "guilty",
                     *           "sentence_months": 84
                     *         },
                     *         "legal_basis": [
                     *           "Pasal 12 huruf a UU 31/1999 jo UU 20/2001"
                     *         ],
                     *         "is_landmark_case": false,
                     *         "summary_id": "Kepala Dinas PUPR Kabupaten X terbukti menerima suap dari PT Maju Jaya."
                     *       }
                     *     }
                     */
                    "application/json": components["schemas"]["GetCaseResponse"];
                };
            };
            /** @description Case not found */
            404: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "error": "case not found",
                     *       "status_code": 404
                     *     }
                     */
                    "application/json": components["schemas"]["Error"];
                };
            };
        };
    };
    getCouncilCaseStatistics: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Statistics */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "total_cases": 1250,
                     *       "sentence_distribution": {
                     *         "corruption": {
                     *           "avg_months": 66.5,
                     *           "count": 580
                     *         },
                     *         "narcotics": {
                     *           "avg_months": 48.2,
                     *           "count": 425
                     *         }
                     *       },
                     *       "verdict_distribution": {
                     *         "guilty": 1180,
                     *         "acquitted": 70
                     *       }
                     *     }
                     */
                    "application/json": components["schemas"]["CaseStatisticsResponse"];
                };
            };
        };
    };
    getHealth: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Service is alive */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "status": "ok"
                     *     }
                     */
                    "application/json": {
                        /** @example ok */
                        status?: string;
                    };
                };
            };
        };
    };
    getReady: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Service is ready */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "status": "ready",
                     *       "database": "connected",
                     *       "redis": "connected"
                     *     }
                     */
                    "application/json": {
                        status?: string;
                        database?: string;
                        redis?: string;
                    };
                };
            };
            /** @description Service not ready */
            503: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    /**
                     * @example {
                     *       "status": "not_ready",
                     *       "database": "connected",
                     *       "redis": "disconnected"
                     *     }
                     */
                    "application/json": {
                        status?: string;
                        database?: string;
                        redis?: string;
                    };
                };
            };
        };
    };
}
