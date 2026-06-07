export type paths = {
    "/health": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Health check endpoint
         * @description Liveness probe endpoint that confirms the API process is running.
         *     Used by container orchestrators (Docker, Kubernetes) for health checks.
         */
        get: operations["healthCheck"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/spse-http": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit SPSE HTTP crawler job (no browser)
         * @description Submit an SPSE crawl job that uses plain HTTP requests to spse.inaproc.id
         *     instead of a browser. Faster and more reliable than browser-based crawling.
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitSpseHttpCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/spse-http/batch": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit SPSE HTTP crawler jobs for multiple tender types and years
         * @description Creates separate HTTP-based crawl jobs for each tender type and year combination.
         *     Supports multi-year batching via tahun_list (cross-product with tender_types).
         *     Poll each job_id individually for status. Duplicate tender_types and years are rejected.
         */
        post: operations["submitSpseHttpBatchCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/lpse-sites": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List available LPSE sites
         * @description Returns a paginated list of pre-configured LPSE (Layanan Pengadaan Secara Elektronik) sites.
         *     Use these codes when submitting SPSE crawl jobs to avoid manually entering base URLs.
         */
        get: operations["listLpseSites"];
        put?: never;
        /**
         * Create an LPSE site
         * @description Creates a single LPSE site directory row for operational maintenance.
         *     Requires bearer management API key authentication.
         */
        post: operations["createLpseSite"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/lpse-sites/{code}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get a specific LPSE site by code
         * @description Returns configuration for a specific LPSE site.
         *     Use this to get the base URL and metadata for a known site code.
         */
        get: operations["getLpseSite"];
        put?: never;
        post?: never;
        /**
         * Delete an LPSE site
         * @description Deletes a single LPSE site directory row for operational maintenance.
         *     Requires bearer management API key authentication.
         */
        delete: operations["deleteLpseSite"];
        options?: never;
        head?: never;
        /**
         * Update an LPSE site
         * @description Updates a single LPSE site directory row for operational maintenance.
         *     Omitted fields are left unchanged. Requires bearer management API key authentication.
         */
        patch: operations["updateLpseSite"];
        trace?: never;
    };
    "/api/v1/crawl/bpk": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit BPK regulation crawler job
         * @description Submit a new BPK regulation crawler job.
         *     Crawls https://peraturan.bpk.go.id/Search with the specified filters.
         */
        post: operations["submitBpkCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/lkpp": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit LKPP Blacklist crawler job
         * @description Crawls the LKPP Daftar Hitam (blacklisted vendors) database at
         *     https://daftar-hitam.inaproc.id/ using the GraphQL API.
         *     Full crawl takes ~5 minutes for all 5,000+ entries.
         */
        post: operations["submitLkppBlacklistCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/mahkamah-agung": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit Mahkamah Agung crawler job
         * @description Submit a new Mahkamah Agung (Supreme Court) putusan crawler job.
         *     Crawls court decisions from https://putusan3.mahkamahagung.go.id
         *     with optional search filters for classification, verdict, court level, and year.
         */
        post: operations["submitMahkamahAgungCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/mahkamah-agung/pdf": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit Mahkamah Agung PDF download job
         * @description Submit a slow PDF download job for Mahkamah Agung putusans.
         *     Downloads PDFs one at a time with long delays to avoid rate limiting.
         *     Only downloads PDFs for putusans that have a pdf_url but no pdf_storage_path.
         */
        post: operations["submitMahkamahAgungPdfDownload"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/mahkamah-agung/putusans": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Query putusans with filters
         * @description Query stored Mahkamah Agung court decisions with optional filtering
         *     by court level (tingkat_proses), verdict (amar), year (tahun), and more.
         */
        get: operations["queryPutusans"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/mahkamah-agung/putusans/{putusan_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get single putusan by ID */
        get: operations["getPutusan"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/mahkamah-agung/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get putusan aggregate statistics
         * @description Returns aggregate statistics for stored putusans by court level, verdict, and year.
         */
        get: operations["getPutusanStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/singapore": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit Singapore E-Litigation crawler job
         * @description Submit a new Singapore E-Litigation judgment crawler job.
         *     Crawls court judgments from https://www.elitigation.sg/gd
         *     with optional search filters for keyword, year, and court type.
         */
        post: operations["submitSingaporeCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/singapore/judgments": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Query Singapore judgments with filters
         * @description Query stored Singapore court judgments with optional filtering
         *     by court type, year, keyword, and more.
         */
        get: operations["querySingaporeJudgments"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/singapore/judgments/{citation}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get single Singapore judgment by citation */
        get: operations["getSingaporeJudgment"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/singapore/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get Singapore judgment aggregate statistics
         * @description Returns aggregate statistics for stored judgments by court type and year.
         */
        get: operations["getSingaporeJudgmentStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sprm": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit SPRM Malaysia crawler job
         * @description Submit a new SPRM (Suruhanjaya Pencegahan Rasuah Malaysia) crawler job.
         *     Crawls corruption offenders from https://www.sprm.gov.my/index.php?id=21&page_id=96
         */
        post: operations["submitSprmCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sprm/offenders": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Query SPRM offenders with filters
         * @description Query stored SPRM corruption offenders with optional filtering
         *     by state, category, and more.
         */
        get: operations["querySprmOffenders"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sprm/offenders/{offender_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get single SPRM offender by ID */
        get: operations["getSprmOffender"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sprm/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get SPRM offender aggregate statistics
         * @description Returns aggregate statistics for stored offenders by state and category.
         */
        get: operations["getSprmOffenderStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit OpenTender crawler job
         * @description Submit a new OpenTender API crawler job.
         *     Crawls Indonesian government procurement tenders from https://pro.opentender.net/api/tender/
         *     using direct API consumption (no browser needed).
         */
        post: operations["submitOpenTenderCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/ocds": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit OpenTender OCDS batch export crawl job
         * @description Submit a job to download and process OCDS (Open Contracting Data Standard)
         *     batch export from OpenTender. Downloads ZIP file containing OCDS-format JSON
         *     for the specified year and LPSE code.
         */
        post: operations["submitOpenTenderOcdsCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/tenders": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Query OpenTender tenders with filters
         * @description Query stored OpenTender procurement tenders with optional filtering
         *     by LPSE code, fiscal year, and category.
         */
        get: operations["queryOpenTenderTenders"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/tenders/{tender_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get single OpenTender tender by ID */
        get: operations["getOpenTenderTender"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/ocds/releases": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Query OpenTender OCDS releases with filters
         * @description Query stored OCDS releases from OpenTender.net API with optional filtering
         *     by LPSE code, fiscal year, buyer name, tender status, and OCID.
         */
        get: operations["queryOpentenderOcdsReleases"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/ocds/releases/{release_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get single OCDS release by ID */
        get: operations["getOpentenderOcdsReleaseById"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/master/lpse": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get LPSE master data
         * @description Returns a paginated list of LPSE (Layanan Pengadaan Secara Elektronik) units
         *     from OpenTender master data. Use the code for filtering tenders by LPSE.
         */
        get: operations["getOpentenderMasterLpse"];
        put?: never;
        /**
         * Create LPSE master data
         * @description Creates one OpenTender LPSE master-data row. Requires bearer management API key authentication.
         */
        post: operations["createOpentenderMasterLpse"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/master/lpse/{code}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get LPSE master data by code
         * @description Returns one OpenTender LPSE master-data row.
         */
        get: operations["getOpentenderMasterLpseByCode"];
        put?: never;
        post?: never;
        /**
         * Delete LPSE master data
         * @description Deletes one OpenTender LPSE master-data row. Requires bearer management API key authentication.
         */
        delete: operations["deleteOpentenderMasterLpse"];
        options?: never;
        head?: never;
        /**
         * Update LPSE master data
         * @description Updates one OpenTender LPSE master-data row. Requires bearer management API key authentication.
         */
        patch: operations["updateOpentenderMasterLpse"];
        trace?: never;
    };
    "/api/v1/crawl/opentender/master/instansi": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get institution master data
         * @description Returns a paginated list of government institutions (instansi) from OpenTender master data.
         *     Includes BUMN, BUMD, and government agencies.
         */
        get: operations["getOpentenderMasterInstansi"];
        put?: never;
        /**
         * Create institution master data
         * @description Creates one OpenTender instansi master-data row. Requires bearer management API key authentication.
         */
        post: operations["createOpentenderMasterInstansi"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/master/instansi/{code}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get institution master data by code
         * @description Returns one OpenTender instansi master-data row.
         */
        get: operations["getOpentenderMasterInstansiByCode"];
        put?: never;
        post?: never;
        /**
         * Delete institution master data
         * @description Deletes one OpenTender instansi master-data row. Requires bearer management API key authentication.
         */
        delete: operations["deleteOpentenderMasterInstansi"];
        options?: never;
        head?: never;
        /**
         * Update institution master data
         * @description Updates one OpenTender instansi master-data row. Requires bearer management API key authentication.
         */
        patch: operations["updateOpentenderMasterInstansi"];
        trace?: never;
    };
    "/api/v1/crawl/opentender/master/skpd": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get SKPD master data
         * @description Returns the list of all SKPD (Satuan Kerja Perangkat Daerah) units from OpenTender master data.
         *     These are regional government work units.
         */
        get: operations["getOpentenderMasterSkpd"];
        put?: never;
        /**
         * Create SKPD master data
         * @description Creates one OpenTender SKPD master-data row. Requires bearer management API key authentication.
         */
        post: operations["createOpentenderMasterSkpd"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/master/skpd/{code}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get SKPD master data by code
         * @description Returns one OpenTender SKPD master-data row.
         */
        get: operations["getOpentenderMasterSkpdByCode"];
        put?: never;
        post?: never;
        /**
         * Delete SKPD master data
         * @description Deletes one OpenTender SKPD master-data row. Requires bearer management API key authentication.
         */
        delete: operations["deleteOpentenderMasterSkpd"];
        options?: never;
        head?: never;
        /**
         * Update SKPD master data
         * @description Updates one OpenTender SKPD master-data row. Requires bearer management API key authentication.
         */
        patch: operations["updateOpentenderMasterSkpd"];
        trace?: never;
    };
    "/api/v1/crawl/opentender/master/source-fund": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get source fund master data
         * @description Returns a paginated list of funding sources (sumber dana) from OpenTender master data.
         *     Includes APBN, APBD, BUMN, BUMD, etc.
         */
        get: operations["getOpentenderMasterSourceFund"];
        put?: never;
        /**
         * Create source-fund master data
         * @description Creates one OpenTender source-fund master-data row. Requires bearer management API key authentication.
         */
        post: operations["createOpentenderMasterSourceFund"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/opentender/master/source-fund/{key}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get source-fund master data by key
         * @description Returns one OpenTender source-fund master-data row.
         */
        get: operations["getOpentenderMasterSourceFundByKey"];
        put?: never;
        post?: never;
        /**
         * Delete source-fund master data
         * @description Deletes one OpenTender source-fund master-data row. Requires bearer management API key authentication.
         */
        delete: operations["deleteOpentenderMasterSourceFund"];
        options?: never;
        head?: never;
        /**
         * Update source-fund master data
         * @description Updates one OpenTender source-fund master-data row. Requires bearer management API key authentication.
         */
        patch: operations["updateOpentenderMasterSourceFund"];
        trace?: never;
    };
    "/api/v1/crawl/sirup": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit SIRUP RUP package crawler job
         * @description Submit a new SIRUP (Sistem Informasi Rencana Umum Pengadaan) crawler job.
         *     Crawls RUP (Rencana Umum Pengadaan) packages from https://sirup.inaproc.id
         *     for either Paket Penyedia or Paket Swakelola.
         */
        post: operations["submitSirupCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sirup/paket": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Query crawled SIRUP packages
         * @description Query stored SIRUP RUP packages with optional filtering.
         */
        get: operations["querySirupPaket"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sirup/paket/{kode_rup}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get SIRUP package by kode_rup */
        get: operations["getSirupPaket"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/interpol": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit Interpol Red Notice crawl job
         * @description Submit a new crawl job to fetch Interpol Red Notices from the public API.
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitInterpolCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/interpol/notices": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List Interpol Red Notices
         * @description Query stored Interpol Red Notices with optional filters.
         *     Supports filtering by nationality and wanting country.
         */
        get: operations["listInterpolNotices"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/interpol/notices/{entity_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single Interpol Red Notice by entity_id
         * @description Retrieve a specific Interpol Red Notice by its Interpol entity ID.
         */
        get: operations["getInterpolNotice"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/interpol/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get Interpol Red Notice statistics
         * @description Get aggregate statistics about stored Interpol Red Notices.
         */
        get: operations["getInterpolStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/uk-companies-house": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit UK Companies House disqualified officers crawl job
         * @description Submit a new crawl job to download the full UK Companies House
         *     Register of Disqualifications (natural persons and corporate entities).
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitUkCompaniesHouseCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/uk-companies-house/officers": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List UK disqualified officers
         * @description Query stored UK disqualified officers with optional filters.
         *     Supports filtering by type (natural/corporate), nationality, and active status.
         */
        get: operations["listUkDisqualifiedOfficers"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/uk-companies-house/officers/{officer_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single UK disqualified officer by Companies House ID
         * @description Retrieve a specific disqualified officer by their Companies House officer ID.
         */
        get: operations["getUkDisqualifiedOfficer"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/uk-companies-house/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get UK disqualified officers statistics
         * @description Get aggregate statistics about stored UK disqualified officers.
         */
        get: operations["getUkCompaniesHouseStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sg-mas": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit SG MAS enforcement actions crawl job
         * @description Submit a new crawl job to download enforcement actions from the
         *     Monetary Authority of Singapore (MAS). Fetches list page and detail pages.
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitSgMasCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sg-mas/enforcement-actions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List MAS enforcement actions
         * @description Query stored MAS enforcement actions with optional filters.
         *     Supports filtering by action type and title search.
         */
        get: operations["listSgMasEnforcementActions"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sg-mas/enforcement-actions/{id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single MAS enforcement action by ID
         * @description Retrieve a specific enforcement action by its internal database UUID.
         *     Includes full article content.
         */
        get: operations["getSgMasEnforcementAction"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sg-mas/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get MAS enforcement actions statistics
         * @description Get aggregate statistics about stored MAS enforcement actions.
         */
        get: operations["getSgMasStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sc-malaysia": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit SC Malaysia crawl job
         * @description Submit a new crawl job for Securities Commission Malaysia data.
         *     Use sub_type to select which dataset to crawl:
         *     - aob_sanctions: Audit Oversight Board disciplinary actions
         *     - investor_alerts: Unauthorized entities investor alert list
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitScMalaysiaCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sc-malaysia/aob-sanctions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List AOB sanctions
         * @description Query stored SC Malaysia AOB sanctions with optional filters.
         *     Supports filtering by year and auditor name search.
         */
        get: operations["listScAobSanctions"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sc-malaysia/aob-sanctions/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get AOB sanctions statistics
         * @description Get aggregate statistics about stored AOB sanctions.
         */
        get: operations["getScAobSanctionsStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sc-malaysia/aob-sanctions/{id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single AOB sanction by ID
         * @description Retrieve a specific AOB sanction by its internal database UUID.
         *     Includes full description field.
         */
        get: operations["getScAobSanction"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sc-malaysia/investor-alerts": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List investor alerts
         * @description Query stored SC Malaysia investor alerts with optional filters.
         *     Supports filtering by entity type and name search.
         */
        get: operations["listScInvestorAlerts"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sc-malaysia/investor-alerts/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get investor alerts statistics
         * @description Get aggregate statistics about stored investor alerts.
         */
        get: operations["getScInvestorAlertsStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/sc-malaysia/investor-alerts/{id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single investor alert by ID
         * @description Retrieve a specific investor alert by its internal database UUID.
         *     Includes addresses and websites arrays.
         */
        get: operations["getScInvestorAlert"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/adb-sanctions": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List ADB sanctions
         * @description Query stored ADB sanctions with optional filters.
         */
        get: operations["listAdbSanctions"];
        put?: never;
        /**
         * Submit ADB sanctions list crawl job
         * @description Submit a new crawl job for the Asian Development Bank sanctions list.
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitAdbSanctionsCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/adb-sanctions/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get ADB sanctions statistics
         * @description Get aggregate statistics about stored ADB sanctions.
         */
        get: operations["getAdbSanctionsStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/adb-sanctions/{adb_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single ADB sanction by ADB ID
         * @description Retrieve a specific ADB sanction by the ADB record ID (24-char hex).
         */
        get: operations["getAdbSanction"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/ppatk-dttot": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List PPATK DTTOT entities
         * @description Query stored PPATK DTTOT entities with optional filters.
         */
        get: operations["listPpatkDttot"];
        put?: never;
        /**
         * Submit PPATK DTTOT crawl job
         * @description Submit a new crawl job for the PPATK DTTOT Excel source.
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitPpatkDttotCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/ppatk-dttot/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get PPATK DTTOT statistics
         * @description Get aggregate statistics about stored PPATK DTTOT entities.
         */
        get: operations["getPpatkDttotStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/ppatk-dttot/{densus_code}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single PPATK DTTOT entity by Densus code
         * @description Retrieve a specific PPATK DTTOT entity by its Densus code.
         */
        get: operations["getPpatkDttotByDensusCode"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/world-bank-debarred": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List World Bank debarred entities
         * @description Query stored World Bank debarred records with optional filters.
         */
        get: operations["listWorldBankDebarred"];
        put?: never;
        /**
         * Submit World Bank debarred entities crawl job
         * @description Submit a new crawl job for the World Bank Listing of Ineligible Firms and Individuals.
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitWorldBankDebarredCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/world-bank-debarred/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get World Bank debarred statistics
         * @description Get aggregate statistics about stored World Bank debarred records.
         */
        get: operations["getWorldBankDebarredStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/world-bank-debarred/{supp_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single World Bank debarred record by supplier ID
         * @description Retrieve a specific World Bank debarred record by supplier ID.
         */
        get: operations["getWorldBankDebarredRecord"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/eu-most-wanted": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Submit EU Most Wanted fugitives crawl job
         * @description Submit a new crawl job to extract fugitive data from eumostwanted.eu.
         *     Poll GET /api/v1/crawl/{job_id} to check status.
         */
        post: operations["submitEUMostWantedCrawl"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/eu-most-wanted/fugitives": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List EU Most Wanted fugitives
         * @description Query stored EU Most Wanted fugitives with optional filters.
         *     Supports filtering by country and name search.
         */
        get: operations["listEUMostWantedFugitives"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/eu-most-wanted/fugitives/{node_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get single EU Most Wanted fugitive by node_id
         * @description Retrieve a specific EU Most Wanted fugitive by their Drupal node ID.
         */
        get: operations["getEUMostWantedFugitive"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** List recent jobs */
        get: operations["listJobs"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/jobs/summary": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get aggregated job summary */
        get: operations["getJobSummary"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/queue/stats": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get queue statistics */
        get: operations["getQueueStats"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/recent": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get recent jobs for each crawler type
         * @description Returns the N most recent jobs for each crawler type, grouped by crawler.
         *     Useful for showing recent activity in the job submission UI so users can
         *     see what was previously crawled and re-use parameters.
         */
        get: operations["getRecentJobsPerCrawler"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/{job_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get job status
         * @description Poll this endpoint every 2-5 seconds to check job progress.
         */
        get: operations["getJobStatus"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        /**
         * Update persisted job data
         * @description Update a queued or terminal crawler job record.
         *     Running jobs cannot be updated through this endpoint because the worker
         *     owns their live execution state after dequeue.
         *
         *     Requires `expected_updated_at` for optimistic concurrency. If the
         *     stored row changed since the client last read it, the API returns 409.
         *     If `crawler_type` or `params` change, the effective crawler request is
         *     revalidated with the same schema used by job submission endpoints.
         */
        patch: operations["updateJob"];
        trace?: never;
    };
    "/api/v1/crawl/{job_id}/cancel": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Cancel a job
         * @description Sets a cancel flag that the worker checks periodically.
         *     Job will be cancelled at the next checkpoint (between pages).
         */
        post: operations["cancelJob"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/{job_id}/resume": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Resume a failed or cancelled job from its checkpoint
         * @description Creates a new job that continues from the checkpoint of a failed or
         *     cancelled job. The new job inherits the original job's params and
         *     starts crawling from the last completed page + 1.
         *
         *     Returns 409 if the job is not in a resumable state (must be failed
         *     or cancelled) or if an active resume job already exists.
         */
        post: operations["resumeJob"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/{job_id}/retry": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Retry a failed job from a fresh start
         * @description Creates a new queued job using the failed job's crawler type and params.
         *     The retry lineage is preserved via resumed_from_job_id so automated
         *     retry chains can be capped by the ops agent.
         */
        post: operations["retryJob"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/{job_id}/logs/stream": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Stream job logs via SSE
         * @description Stream real-time logs for a job via Server-Sent Events (SSE).
         *
         *     Connect to receive logs as they are produced by the worker.
         *     The stream closes automatically when:
         *     - The job completes (receives completion event)
         *     - The client disconnects
         *     - The connection times out
         *
         *     **Authentication**: Since the EventSource API doesn't support custom headers,
         *     the API key must be provided as a query parameter.
         *
         *     **Security Note**: API keys in query parameters may appear in server logs and
         *     browser history. For production deployments:
         *     - Configure reverse proxy to exclude query params from access logs
         *     - Use short-lived session tokens for SSE authentication if possible
         *     - Monitor for unauthorized access attempts
         *
         *     **Client Usage**:
         *     ```javascript
         *     const eventSource = new EventSource(
         *       `/api/v1/crawl/${jobId}/logs/stream?api_key=${apiKey}`
         *     );
         *
         *     eventSource.onmessage = (event) => {
         *       const log = JSON.parse(event.data);
         *       console.log(`[${log.level}] ${log.message}`);
         *
         *       if (log.event === "completed") {
         *         eventSource.close();
         *       }
         *     };
         *     ```
         */
        get: operations["streamJobLogs"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/{job_id}/logs": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get historical logs for a job
         * @description Retrieve stored logs for a job from the database.
         *     Returns the last 100 log entries stored in the job's recent_logs column.
         *     Supports filtering by log level.
         */
        get: operations["getJobLogs"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/schedules": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * List recurring schedules
         * @description List all recurring crawl schedules with optional filtering by status.
         */
        get: operations["listSchedules"];
        put?: never;
        /**
         * Create a recurring schedule
         * @description Create a new recurring crawl schedule. The schedule will automatically
         *     create jobs based on the configured interval.
         */
        post: operations["createSchedule"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/schedules/{schedule_id}": {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Schedule UUID */
                schedule_id: string;
            };
            cookie?: never;
        };
        /**
         * Get schedule details
         * @description Get details of a specific recurring schedule.
         */
        get: operations["getSchedule"];
        put?: never;
        post?: never;
        /**
         * Delete a schedule
         * @description Delete a recurring schedule. This does not affect jobs already created.
         */
        delete: operations["deleteSchedule"];
        options?: never;
        head?: never;
        /**
         * Update schedule
         * @description Update schedule parameters, interval, or status.
         *     Use status field to pause/resume a schedule.
         */
        patch: operations["updateSchedule"];
        trace?: never;
    };
    "/api/v1/crawlers/status": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get all crawler health status
         * @description Returns health status, schedule counts, and 24h job statistics
         *     for all known crawler types. Used by the admin dashboard.
         */
        get: operations["getCrawlerStatus"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawlers/status/{crawler_type}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get detailed status for a single crawler
         * @description Returns health check details, recent jobs, and schedule information
         *     for a specific crawler type. Used by the admin detail view.
         */
        get: operations["getCrawlerStatusDetail"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/health-checks/probe/{crawler_type}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        get?: never;
        put?: never;
        /**
         * Trigger an immediate health check probe
         * @description Runs a health check probe for the specified crawler type and returns
         *     the result inline. Rate-limited to once per 5 minutes per crawler type.
         */
        post: operations["triggerProbe"];
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/spse-http/tenders": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Query tenders with filters */
        get: operations["queryTenders"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/spse-http/tenders/{tender_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get single tender by ID */
        get: operations["getTender"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/lkpp/entries": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Query blacklist entries with filters */
        get: operations["queryBlacklistEntries"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/lkpp/entries/{entry_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get single blacklist entry */
        get: operations["getBlacklistEntry"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/bpk/types": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get BPK regulation types
         * @description Returns regulation types from static JSON data.
         */
        get: operations["getBpkTypes"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/bpk/themes": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get BPK themes */
        get: operations["getBpkThemes"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/bpk/subjects": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Get BPK subjects
         * @description Use subject `id` as the `tema` parameter in crawl requests.
         */
        get: operations["getBpkSubjects"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/bpk/regulations": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /**
         * Query BPK regulations with filters
         * @description Query crawled BPK regulations with optional filters and pagination.
         *     Returns regulations sorted by created_at DESC.
         */
        get: operations["queryBpkRegulations"];
        put?: never;
        post?: never;
        delete?: never;
        options?: never;
        head?: never;
        patch?: never;
        trace?: never;
    };
    "/api/v1/crawl/bpk/regulations/{regulation_id}": {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        /** Get single BPK regulation by ID */
        get: operations["getBpkRegulation"];
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
         * @description SPSE tender type
         * @enum {string}
         */
        TenderType: "lelang" | "nontender" | "pencatatan" | "swakelola" | "darurat";
        /**
         * @description Job execution status
         * @enum {string}
         */
        JobStatus: "queued" | "running" | "completed" | "failed" | "cancelled";
        /**
         * @description LKPP blacklist entry status
         * @enum {string}
         */
        BlacklistStatus: "PUBLISHED" | "CANCELLED" | "CANCELED" | "CANCELED_TEMPORARY" | "CANCELED_PERMANENT" | "EXPIRED" | "PENDING";
        /**
         * @description BPK regulation status
         * @enum {string}
         */
        BPKRegulationStatus: "Berlaku" | "Dicabut" | "Tidak Berlaku";
        /**
         * @description How often the schedule runs
         * @enum {string}
         */
        ScheduleInterval: "daily" | "weekly" | "fortnightly" | "monthly";
        /**
         * @description Schedule status
         * @enum {string}
         */
        ScheduleStatus: "active" | "paused";
        /**
         * @description Type of crawler
         * @enum {string}
         */
        CrawlerType: "bpk" | "lkpp_blacklist" | "mahkamah_agung" | "singapore" | "sprm" | "opentender" | "opentender_ocds" | "sirup" | "mahkamah_agung_pdf" | "interpol" | "eu_most_wanted" | "spse_http" | "sc_malaysia" | "adb_sanctions" | "ppatk_dttot" | "world_bank_debarred" | "ppatk_dttot" | "world_bank_debarred";
        /** @description Business license requirement */
        IzinUsaha: {
            /** @description License type (e.g., NIB, SBU) */
            jenis_izin?: string;
            /** @description Business field/KBLI code description */
            bidang_usaha?: string;
        };
        /** @description Administrative qualification requirement */
        KualifikasiAdministrasi: {
            /**
             * @description Type of requirement
             * @enum {string}
             */
            type?: "requirement" | "izin_usaha";
            /** @description Requirement text (for type=requirement) */
            text?: string | null;
            /** @description License data (for type=izin_usaha) */
            data?: components["schemas"]["IzinUsaha"][] | null;
        };
        /** @description KBKI (Klasifikasi Baku Komoditas Indonesia) classification */
        KBKIClassification: {
            /** @description Division code */
            divisi?: string;
            /** @description Group code */
            kelompok?: string;
            /** @description Description */
            deskripsi?: string;
            /** @description KBKI version year */
            tahun?: string;
        };
        /** @description Detailed qualification requirements from pengumuman tab */
        SyaratKualifikasi: {
            /**
             * @description Administrative/legal qualification requirements
             * @default []
             */
            administrasi: components["schemas"]["KualifikasiAdministrasi"][];
            /**
             * @description Technical qualification requirements
             * @default []
             */
            teknis: string[];
            /**
             * @description KBKI classification requirements
             * @default []
             */
            kbki: components["schemas"]["KBKIClassification"][];
        } | null;
        /** @description Contract execution/realization milestone entry */
        RealisasiEntry: {
            /** @description Entry number */
            no?: number;
            /** @description Realization type (e.g., Surat Pesanan, BAST, Pembayaran) */
            jenis_realisasi?: string;
            /** @description Realization value in Indonesian currency format */
            nilai_realisasi?: string;
            /** @description Realization date */
            tanggal_realisasi?: string;
        };
        /** @description Contract execution/realization data from pemenang berkontrak tab */
        Realisasi: {
            /** @description Total realization value */
            nilai_total_realisasi?: string | null;
            /** @description Domestic product value (Produk Dalam Negeri) */
            nilai_pdn?: string | null;
            /** @description Small/micro business value (Usaha Mikro Kecil) */
            nilai_umk?: string | null;
            /** @description Package completion date */
            tanggal_selesai?: string | null;
            /**
             * @description List of realization milestone entries
             * @default []
             */
            entries: components["schemas"]["RealisasiEntry"][];
        } | null;
        /**
         * @description Request to start an SPSE HTTP-based crawl job.
         *     Uses plain HTTP requests to spse.inaproc.id instead of a browser.
         *     Extracts all detail-tab data (pengumuman, peserta, jadwal, hasil,
         *     pemenang, pemenang_berkontrak) and PDFs — same as the browser crawler.
         *     Only difference: no custom base_url (hardcoded to spse.inaproc.id).
         */
        SPSEHttpCrawlRequest: {
            /**
             * @description LPSE code (e.g., 'jakarta', 'kemenkeu')
             * @default jakarta
             */
            lpse_code: string;
            /** @description Tahun Anggaran (fiscal year). Defaults to current year. */
            tahun?: string;
            /** @default lelang */
            tender_type: components["schemas"]["TenderType"];
            /** @description Maximum pages to crawl. Omit for unlimited. */
            max_pages?: number | null;
            /**
             * @description Jenis Pengadaan filter. Values: 'Pengadaan Barang', 'Pekerjaan Konstruksi',
             *     'Jasa Konsultansi Badan Usaha Non Konstruksi', etc.
             */
            jenis_pengadaan?: string | null;
            /** @description General search query. */
            search?: string | null;
            /**
             * @description Whether to download and upload PDFs to object storage.
             * @default true
             */
            download_pdfs: boolean;
        };
        /**
         * @description Request to start multiple SPSE HTTP-based crawl jobs for different tender types.
         *     Uses plain HTTP requests to spse.inaproc.id instead of a browser.
         */
        SPSEHttpBatchCrawlRequest: {
            /**
             * @description LPSE code (e.g., 'jakarta', 'kemenkeu')
             * @default jakarta
             */
            lpse_code: string;
            /** @description Tahun Anggaran (fiscal year). Defaults to current year. Mutually exclusive with tahun_list. */
            tahun?: string;
            /** @description List of fiscal years to crawl. Creates one job per year per tender type (cross-product). Mutually exclusive with tahun. */
            tahun_list?: string[];
            /** @description List of tender types to crawl. Duplicates not allowed. */
            tender_types: components["schemas"]["TenderType"][];
            /** @description Maximum pages to crawl per job. Omit for unlimited. */
            max_pages?: number | null;
            /**
             * @description Whether to download and upload PDFs to object storage.
             * @default true
             */
            download_pdfs: boolean;
        };
        /** @description Result for a single job in batch submission */
        SPSEBatchJobResult: {
            tender_type: components["schemas"]["TenderType"];
            /** @description Fiscal year for this job. */
            tahun?: string;
            /**
             * Format: uuid
             * @description Present if job created successfully
             */
            job_id?: string;
            /** @description Present if job creation failed */
            error?: string;
        };
        /** @description Pre-configured LPSE site information */
        LPSESite: {
            /**
             * @description Unique identifier for this LPSE site (e.g., 'polri-archive', 'jakarta')
             * @example polri-archive
             */
            code: string;
            /**
             * @description Human-readable name for display
             * @example Kepolisian RI - Archive
             */
            name: string;
            /**
             * Format: uri
             * @description Base URL for the LPSE site
             * @example https://lpse-archive.polri.go.id/eproc4
             */
            base_url: string;
            /**
             * @description Region/province if applicable
             * @example DKI Jakarta
             */
            region?: string | null;
            /**
             * @description Contact email for the LPSE
             * @example lpse@polri.go.id
             */
            email?: string | null;
            /**
             * @description Type of LPSE: SYSTEM_PROVIDER or SERVICE_PROVIDER
             * @example SYSTEM_PROVIDER
             */
            lpse_type?: string | null;
            /**
             * @description Administrative status: Aktif or Non Aktif
             * @example Aktif
             */
            status?: string | null;
            /** @description Online status from eproc.lkpp.go.id */
            is_online?: boolean | null;
            /** @description Standardization status from eproc.lkpp.go.id */
            standardisasi?: string | null;
            /** @description Staff count label from eproc.lkpp.go.id */
            pegawai?: string | null;
            /** @description Activity count label from eproc.lkpp.go.id */
            kegiatan?: string | null;
            /**
             * @description SPSE software version
             * @example 4.5u20240923
             */
            spse_version?: string | null;
            /**
             * @description Last updated date from eproc.lkpp.go.id
             * @example 29 Aug 2023
             */
            updated_at?: string | null;
        };
        /** @description List of available LPSE sites */
        LPSESiteListResponse: {
            /** @description List of available LPSE sites */
            sites: components["schemas"]["LPSESite"][];
            /** @description Total number of sites matching the applied search and filters */
            total: number;
            /** @description Max results returned in this page */
            limit: number;
            /** @description Pagination offset used for this page */
            offset: number;
        };
        LPSESiteCreateRequest: {
            code: string;
            name: string;
            /** Format: uri */
            base_url: string;
            region?: string | null;
            email?: string | null;
            lpse_type?: string | null;
            status?: string | null;
            is_online?: boolean | null;
            standardisasi?: string | null;
            pegawai?: string | null;
            kegiatan?: string | null;
            spse_version?: string | null;
            updated_at?: string | null;
        };
        LPSESiteUpdateRequest: {
            name?: string;
            /** Format: uri */
            base_url?: string;
            region?: string | null;
            email?: string | null;
            lpse_type?: string | null;
            status?: string | null;
            is_online?: boolean | null;
            standardisasi?: string | null;
            pegawai?: string | null;
            kegiatan?: string | null;
            spse_version?: string | null;
            updated_at?: string | null;
        };
        /** @description Request to start a BPK regulation crawl job */
        BPKCrawlRequest: {
            /** @description Main keyword search */
            q?: string | null;
            /** @description About/subject text filter */
            tentang?: string | null;
            /** @description Regulation number */
            nomor?: string | null;
            /** @description Year filter (1945-2100) */
            tahun?: number | null;
            /** @description Government entity (e.g., 'Kota Bandung', 'Kementerian Keuangan') */
            entitas?: string | null;
            /**
             * @description Regulation type code (positive integer, >= 1).
             *     Common: 8=UU, 10=PP, 11=Perpres, 19=Perda, 23=Perbup, 27=BPK.
             *     See GET /crawl/bpk/types for full list.
             */
            jenis?: string | null;
            /**
             * @description Subject ID (positive integer, >= 1).
             *     Common: 64=Perpajakan, 23=Kesehatan, 4=APBN.
             *     See GET /crawl/bpk/subjects for full list.
             */
            tema?: string | null;
            status?: components["schemas"]["BPKRegulationStatus"];
            /** @description Maximum pages to crawl (null for unlimited) */
            max_pages?: number | null;
            /** @description Maximum items to extract (null for unlimited) */
            max_items?: number | null;
            /**
             * @description Whether to download and upload PDFs to object storage
             * @default true
             */
            download_pdfs: boolean;
        };
        /** @description Request to start an LKPP Blacklist crawl job */
        LKPPBlacklistCrawlRequest: {
            /** @description Filter by status */
            status_filter?: components["schemas"]["BlacklistStatus"];
            /** @description Maximum pages to crawl. Omit for all pages (~50 pages for full crawl). */
            max_pages?: number | null;
            /**
             * @description Entries per page (max 100)
             * @default 100
             */
            per_page: number;
        };
        /** @description Request to start a Singapore E-Litigation crawl job */
        SingaporeCrawlRequest: {
            /** @description Search keyword */
            keyword?: string | null;
            /**
             * @description Year filter (2000-2025 or "All")
             * @default All
             */
            year: string;
            /**
             * @description Court filter: SUPCT (Supreme Court), etc.
             * @default SUPCT
             */
            court_filter: string;
            /** @description Maximum pages to crawl. Omit for unlimited. */
            max_pages?: number | null;
            /**
             * @description Whether to download and upload PDFs to object storage
             * @default true
             */
            download_pdfs: boolean;
        };
        /** @description Request to start a SPRM Malaysia crawler job */
        SPRMCrawlRequest: {
            /** @description Maximum pages to crawl (8 offenders per page). Omit for unlimited. */
            max_pages?: number | null;
        };
        /** @description Request to start a SIRUP RUP package crawl job */
        SubmitSirupCrawlRequest: {
            /** @description Budget year (tahun anggaran) */
            tahun_anggaran: number;
            /**
             * @description Package type (penyedia or swakelola)
             * @enum {string}
             */
            package_type: "penyedia" | "swakelola";
            /** @description Maximum pages to crawl (100 items per page). Omit for unlimited. */
            max_pages?: number | null;
        };
        SirupPaketResponse: {
            /** @description Unique RUP code */
            kode_rup: string;
            /** @description Package name */
            nama_paket: string;
            /** @description KLPD name (government institution) */
            nama_klpd: string;
            /** @description Work unit */
            satuan_kerja: string;
            /** @description Budget year */
            tahun_anggaran: number;
            /**
             * @description Package type
             * @enum {string}
             */
            package_type: "penyedia" | "swakelola";
            /** @description Work volume */
            volume_pekerjaan?: string | null;
            /** @description Work description */
            uraian_pekerjaan?: string | null;
            /** @description Work specifications */
            spesifikasi_pekerjaan?: string | null;
            /** @description Domestic product requirement */
            produk_dalam_negeri?: boolean;
            /** @description Small business/cooperative requirement */
            usaha_kecil_koperasi?: boolean;
            /** @description Pre-DIPA/DPA status */
            pra_dipa_dpa?: boolean;
            /** @description Total budget ceiling */
            total_pagu?: number | null;
            /** @description Selection method */
            metode_pemilihan?: string | null;
            /** @description Swakelola type (for swakelola packages only) */
            tipe_swakelola?: string | null;
            /**
             * Format: date-time
             * @description Publication date
             */
            tanggal_umumkan?: string | null;
            /**
             * @description Work locations
             * @default []
             */
            lokasi_pekerjaan: {
                [key: string]: unknown;
            }[];
            /**
             * @description Funding sources
             * @default []
             */
            sumber_dana: {
                [key: string]: unknown;
            }[];
            /**
             * @description Procurement types
             * @default []
             */
            jenis_pengadaan: {
                [key: string]: unknown;
            }[];
            /** @description Schedule information */
            jadwal?: {
                [key: string]: unknown;
            };
            /**
             * Format: uri
             * @description Source URL
             */
            source_url: string;
            /** @description Raw data from API */
            raw_data?: {
                [key: string]: unknown;
            } | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        SirupPaketListResponse: {
            items: components["schemas"]["SirupPaketResponse"][];
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Request to start an OpenTender API crawler job */
        OpenTenderCrawlRequest: {
            /** @description LPSE code to crawl (e.g., "10" for Surabaya) */
            lpse_code: string;
            /** @description Maximum pages to crawl (25 tenders per page). Omit for unlimited. */
            max_pages?: number | null;
        };
        /** @description Request to start an OpenTender OCDS batch export crawl job */
        OpenTenderOcdsCrawlRequest: {
            /** @description LPSE code to crawl (e.g., "100" for PLN) */
            lpse_code: string;
            /** @description Fiscal year to download (e.g., 2024) */
            year: number;
        };
        /** @description Request to start a Mahkamah Agung putusan crawl job */
        MahkamahAgungCrawlRequest: {
            /** @description Free text search (q param) */
            keyword?: string | null;
            /** @description Document type: Putusan, Peraturan */
            jenis_doc?: string | null;
            /** @description Classification: Korupsi, Pidana Khusus (cat param) */
            klasifikasi?: string | null;
            /** @description Verdict: Kabul, Tolak, Bebas (jd param) */
            amar?: string | null;
            /** @description Court level: Pertama, Banding, Kasasi, PK (tp param) */
            tingkat_proses?: string | null;
            /** @description Specific court name (court param) */
            pengadilan?: string | null;
            /** @description Decision year (t_put param) */
            tahun_putus?: string | null;
            /** @description Registration year (t_reg param) */
            tahun_register?: string | null;
            /** @description Upload year (t_upl param) */
            tahun_upload?: string | null;
            /** @description Maximum pages to crawl. Omit for unlimited. */
            max_pages?: number | null;
            /**
             * @description Whether to download and upload PDFs to object storage
             * @default true
             */
            download_pdfs: boolean;
        };
        /**
         * @description Request to start a slow PDF download job for Mahkamah Agung putusans.
         *     Downloads PDFs for putusans that have a pdf_url but no pdf_storage_path.
         */
        MahkamahAgungPdfRequest: {
            /**
             * @description Number of PDFs to download per job run
             * @default 10
             */
            batch_size: number;
            /**
             * @description Delay between downloads in seconds (default 10 minutes)
             * @default 600
             */
            delay_seconds: number;
        };
        /** @description Request to start an Interpol Red Notice crawl job. */
        InterpolCrawlRequest: {
            /** @description Maximum pages to crawl (up to 160 notices per page). Omit for unlimited. */
            max_pages?: number | null;
            /** @description Filter by nationality code (e.g., "ID" for Indonesia) */
            nationality?: string | null;
            /** @description Filter by wanting country code (e.g., "US") */
            wanted_by?: string | null;
            /**
             * @description Whether to download and store photos to Garage storage
             * @default true
             */
            download_images: boolean;
        };
        /** @description Interpol Red Notice details. */
        InterpolNoticeResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Interpol notice ID (e.g., "2025-96936") */
            entity_id: string;
            /** @description Family/last name */
            family_name: string;
            /** @description First name */
            forename?: string | null;
            /** @description Array of nationality codes */
            nationality?: string[];
            /** @description Country code of requesting authority */
            wanted_by_country: string;
            /** @description Criminal charges (extracted from raw_data) */
            charges?: string | null;
            /** @description Date of birth (extracted from raw_data) */
            date_of_birth?: string | null;
            /** @description Garage object storage path for photo (e.g., "interpol/2025-96936.jpg") */
            image_path?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of Interpol Red Notices. */
        InterpolNoticeListResponse: {
            items: components["schemas"]["InterpolNoticeResponse"][];
            /** @description Total number of matching notices */
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Statistics about stored Interpol Red Notices. */
        InterpolStatsResponse: {
            /** @description Total number of Red Notices in database */
            total_notices?: number;
            /**
             * Format: date-time
             * @description Timestamp of most recently updated notice
             */
            last_updated?: string | null;
        };
        /** @description Request to start a UK Companies House disqualified officers crawl job. */
        UkCompaniesHouseCrawlRequest: {
            /** @description Maximum letters to process (1-26, A=1, Z=26). Omit for all 26. */
            max_pages?: number | null;
        };
        /** @description UK disqualified officer details (natural person or corporate entity). */
        UkDisqualifiedOfficerResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Companies House officer ID */
            officer_id: string;
            /**
             * @description natural (person) or corporate (company/entity)
             * @enum {string}
             */
            officer_type: "natural" | "corporate";
            /** @description First name (natural persons only) */
            forename?: string | null;
            /** @description Last name (natural persons only) */
            surname?: string | null;
            /** @description Middle/other names (natural persons only) */
            other_forenames?: string | null;
            /** @description Title (e.g., Mr, Mrs) */
            title?: string | null;
            /**
             * Format: date
             * @description Date of birth (natural persons only)
             */
            date_of_birth?: string | null;
            /** @description Nationality (natural persons only) */
            nationality?: string | null;
            /** @description Company name (corporate entities only) */
            company_name?: string | null;
            /** @description Company registration number (corporate entities only) */
            company_number?: string | null;
            /** @description Country of registration (corporate entities only) */
            country_of_registration?: string | null;
            /** @description Companies House person number */
            person_number?: string | null;
            /** @description Array of disqualification records */
            disqualifications?: Record<string, never>[];
            /** @description Array of permission-to-act records */
            permissions_to_act?: Record<string, never>[];
            /**
             * Format: date
             * @description Latest disqualification end date
             */
            latest_disqualified_until?: string | null;
            /**
             * Format: date-time
             * @description Soft-delete timestamp (set when all disqualifications expired)
             */
            expired_at?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of UK disqualified officers. */
        UkDisqualifiedOfficerListResponse: {
            items: components["schemas"]["UkDisqualifiedOfficerResponse"][];
            /** @description Total number of matching officers */
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Statistics about stored UK disqualified officers. */
        UkCompaniesHouseStatsResponse: {
            /** @description Total number of officers in database */
            total_officers?: number;
            /** @description Number of natural persons */
            natural_count?: number;
            /** @description Number of corporate entities */
            corporate_count?: number;
            /** @description Number of currently active disqualifications */
            active_count?: number;
            /**
             * Format: date-time
             * @description Timestamp of most recently updated officer
             */
            last_updated?: string | null;
        };
        /** @description Request to start a SG MAS enforcement actions crawl job. */
        SgMasCrawlRequest: {
            /** @description Maximum number of enforcement actions to process. Omit for all. */
            max_items?: number | null;
        };
        /** @description MAS enforcement action summary (no content field). */
        SgMasEnforcementActionResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Detail page URL on MAS website */
            source_url: string;
            /** @description Enforcement action title from list table */
            title: string;
            /**
             * Format: date
             * @description Date the enforcement action was issued
             */
            issue_date?: string | null;
            /** @description Type: Prohibition Order, Civil Penalty, Composition Penalty, Reprimand, etc. */
            action_type?: string | null;
            /** @description Person or company name from list table */
            person_company?: string | null;
            /** @description Headline from detail page banner */
            headline?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description MAS enforcement action with full article content. */
        SgMasEnforcementActionDetailResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Detail page URL on MAS website */
            source_url: string;
            /** @description Enforcement action title from list table */
            title: string;
            /**
             * Format: date
             * @description Date the enforcement action was issued
             */
            issue_date?: string | null;
            /** @description Type: Prohibition Order, Civil Penalty, Composition Penalty, Reprimand, etc. */
            action_type?: string | null;
            /** @description Person or company name from list table */
            person_company?: string | null;
            /** @description Headline from detail page banner */
            headline?: string | null;
            /** @description Full article body as markdown */
            content?: string | null;
            /** @description Complete raw scraped data */
            raw_data?: Record<string, never> | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of MAS enforcement actions. */
        SgMasEnforcementActionListResponse: {
            items: components["schemas"]["SgMasEnforcementActionResponse"][];
            /** @description Total number of matching enforcement actions */
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Statistics about stored MAS enforcement actions. */
        SgMasStatsResponse: {
            /** @description Total number of enforcement actions in database */
            total_actions?: number;
            /**
             * Format: date-time
             * @description Timestamp of most recently updated action
             */
            last_updated?: string | null;
        };
        /** @description Request to start a SC Malaysia crawl job. */
        ScMalaysiaCrawlRequest: {
            /**
             * @description Which dataset to crawl
             * @enum {string}
             */
            sub_type: "aob_sanctions" | "investor_alerts";
        };
        /** @description AOB sanction summary (no description field). */
        ScAobSanctionResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Sanction year */
            year: number;
            /** @description Sequential number within the year */
            entry_number?: string | null;
            /** @description Violation type */
            nature_of_misconduct: string;
            /** @description Auditor firm or individual name */
            auditor: string;
            /** @description Penalties imposed */
            action_taken?: string | null;
            /**
             * Format: date
             * @description Date of AOB action
             */
            action_date?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description AOB sanction with full description. */
        ScAobSanctionDetailResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Sanction year */
            year: number;
            /** @description Sequential number within the year */
            entry_number?: string | null;
            /** @description Violation type */
            nature_of_misconduct: string;
            /** @description Auditor firm or individual name */
            auditor: string;
            /** @description Brief description of the misconduct */
            description?: string | null;
            /** @description Penalties imposed */
            action_taken?: string | null;
            /**
             * Format: date
             * @description Date of AOB action
             */
            action_date?: string | null;
            /** @description Complete raw scraped data */
            raw_data?: Record<string, never> | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of AOB sanctions. */
        ScAobSanctionListResponse: {
            items: components["schemas"]["ScAobSanctionResponse"][];
            /** @description Total number of matching sanctions */
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Statistics about stored AOB sanctions. */
        ScAobSanctionStatsResponse: {
            /** @description Total number of sanctions in database */
            total_sanctions?: number;
            /**
             * Format: date-time
             * @description Timestamp of most recently updated sanction
             */
            last_updated?: string | null;
        };
        /** @description Investor alert summary (no addresses/websites). */
        ScInvestorAlertResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Entity or individual name */
            name: string;
            /** @description Type: individual or entity */
            entity_type?: string | null;
            /** @description When added to alert list (may be year-only like "2026") */
            date_added?: string | null;
            /** @description Violation or scheme description (raw text) */
            remarks?: string | null;
            /** @description Violation or scheme description as structured list */
            remarks_list?: string[];
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Investor alert with full details including addresses and websites. */
        ScInvestorAlertDetailResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Entity or individual name */
            name: string;
            /** @description Type: individual or entity */
            entity_type?: string | null;
            /** @description List of known addresses */
            addresses?: string[];
            /** @description List of associated websites */
            websites?: string[];
            /** @description When added to alert list (may be year-only like "2026") */
            date_added?: string | null;
            /** @description Violation or scheme description (raw text) */
            remarks?: string | null;
            /** @description Violation or scheme description as structured list */
            remarks_list?: string[];
            /** @description Complete raw scraped data */
            raw_data?: Record<string, never> | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of investor alerts. */
        ScInvestorAlertListResponse: {
            items: components["schemas"]["ScInvestorAlertResponse"][];
            /** @description Total number of matching alerts */
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Statistics about stored investor alerts. */
        ScInvestorAlertStatsResponse: {
            /** @description Total number of alerts in database */
            total_alerts?: number;
            /**
             * Format: date-time
             * @description Timestamp of most recently updated alert
             */
            last_updated?: string | null;
        };
        /** @description Request to start an ADB sanctions list crawl job. No parameters needed — crawls the entire published list. */
        AdbSanctionsCrawlRequest: Record<string, never>;
        /** @description ADB sanction summary. */
        AdbSanctionResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description ADB record ID (24-char hex) */
            adb_id: string;
            /** @description Sanctioned entity name */
            name: string;
            /** @description Type of sanction (e.g. Debarred) */
            sanction_type: string;
            /** @description Entity nationality */
            nationality?: string | null;
            /**
             * @description Inferred entity type
             * @enum {string|null}
             */
            entity_type?: "company" | "person" | null;
            /** @description Whether sanction is currently active */
            is_active: boolean;
            /**
             * Format: date
             * @description When sanction took effect
             */
            effective_date?: string | null;
            /**
             * Format: date
             * @description When sanction expires (null = indefinite)
             */
            lapse_date?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description ADB sanction with full details. */
        AdbSanctionDetailResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description ADB record ID (24-char hex) */
            adb_id: string;
            /** @description Sanctioned entity name */
            name: string;
            /** @description Entity address */
            address?: string | null;
            /** @description Type of sanction */
            sanction_type: string;
            /** @description Alternative names or registration numbers */
            other_name?: string | null;
            /** @description Entity nationality */
            nationality?: string | null;
            /**
             * Format: date
             * @description When sanction took effect
             */
            effective_date?: string | null;
            /**
             * Format: date
             * @description When sanction expires (null = indefinite)
             */
            lapse_date?: string | null;
            /** @description Whether sanction is currently active */
            is_active: boolean;
            /** @description Reason for sanction */
            grounds?: string | null;
            /**
             * @description Inferred entity type
             * @enum {string|null}
             */
            entity_type?: "company" | "person" | null;
            /**
             * Format: date
             * @description Date of last change in source data
             */
            changes_made_on?: string | null;
            /** @description Complete raw API response */
            raw_data?: Record<string, never> | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of ADB sanctions. */
        AdbSanctionListResponse: {
            items: components["schemas"]["AdbSanctionResponse"][];
            /** @description Total number of matching sanctions */
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Statistics about stored ADB sanctions. */
        AdbSanctionStatsResponse: {
            /** @description Total number of sanctions in database */
            total_sanctions?: number;
            /**
             * Format: date-time
             * @description Timestamp of most recently updated sanction
             */
            last_updated?: string | null;
        };
        /** @description Request to start a PPATK DTTOT crawl job. No parameters needed. */
        PpatkDttotCrawlRequest: Record<string, never>;
        /** @description PPATK DTTOT entity summary. */
        PpatkDttotResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Unique Densus code from the source workbook */
            densus_code: string;
            /** @description Full source name, including aliases */
            name: string;
            /**
             * @description PPATK entity type
             * @enum {string}
             */
            entity_type: "Orang" | "Korporasi";
            /** @description Nationality or origin country */
            nationality?: string | null;
            /** @description Birth date string as published by PPATK */
            birth_date?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description PPATK DTTOT entity with full details. */
        PpatkDttotDetailResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Unique Densus code from the source workbook */
            densus_code: string;
            /** @description Full source name, including aliases */
            name: string;
            /** @description Multi-line description field from the workbook */
            description?: string | null;
            /**
             * @description PPATK entity type
             * @enum {string}
             */
            entity_type: "Orang" | "Korporasi";
            /** @description Birth place */
            birth_place?: string | null;
            /** @description Birth date string as published by PPATK */
            birth_date?: string | null;
            /** @description Nationality or origin country */
            nationality?: string | null;
            /** @description Address from the workbook */
            address?: string | null;
            /** @description Complete raw workbook row as stored */
            raw_data?: Record<string, never> | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of PPATK DTTOT entities. */
        PpatkDttotListResponse: {
            items: components["schemas"]["PpatkDttotResponse"][];
            /** @description Total number of matching entities */
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Statistics about stored PPATK DTTOT entities. */
        PpatkDttotStatsResponse: {
            /** @description Total number of entities in database */
            total_entities?: number;
            /**
             * Format: date-time
             * @description Timestamp of most recently updated entity
             */
            last_updated?: string | null;
        };
        /** @description Request to start a World Bank debarred entities crawl job. No parameters needed — crawls the full feed. */
        WorldBankDebarredCrawlRequest: Record<string, never>;
        /** @description World Bank debarred entity summary. */
        WorldBankDebarredResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description World Bank supplier ID */
            supp_id: string;
            /** @description Debarred supplier name */
            name: string;
            /** @description Supplier country name */
            country_name?: string | null;
            /** @description Supplier city */
            city?: string | null;
            /** @description Raw World Bank supplier type code */
            supplier_type_code?: string | null;
            /**
             * @description Derived entity type
             * @enum {string|null}
             */
            entity_type?: "company" | "person" | null;
            /** @description Raw World Bank debarment type code */
            debar_type?: string | null;
            /**
             * Format: date
             * @description Debarment start date
             */
            debar_from_date?: string | null;
            /**
             * Format: date
             * @description Debarment end date (null = indefinite or absent)
             */
            debar_to_date?: string | null;
            /** @description Whether the debarment is indefinite */
            is_indefinite: boolean;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description World Bank debarred entity with full details. */
        WorldBankDebarredDetailResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description World Bank supplier ID */
            supp_id: string;
            /** @description Debarred supplier name */
            name: string;
            /** @description Supplier country name */
            country_name?: string | null;
            /** @description Supplier address */
            address?: string | null;
            /** @description Supplier city */
            city?: string | null;
            /** @description Raw World Bank supplier type code */
            supplier_type_code?: string | null;
            /**
             * @description Derived entity type
             * @enum {string|null}
             */
            entity_type?: "company" | "person" | null;
            /** @description Additional supplier info from the source feed */
            additional_info?: string | null;
            /** @description Raw World Bank debarment type code */
            debar_type?: string | null;
            /**
             * Format: date
             * @description Debarment start date
             */
            debar_from_date?: string | null;
            /**
             * Format: date
             * @description Debarment end date (null = indefinite or absent)
             */
            debar_to_date?: string | null;
            /** @description Whether the debarment is indefinite */
            is_indefinite: boolean;
            /** @description Complete raw API response */
            raw_data?: Record<string, never> | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of World Bank debarred records. */
        WorldBankDebarredListResponse: {
            items: components["schemas"]["WorldBankDebarredResponse"][];
            /** @description Total number of matching records */
            total: number;
            limit: number;
            offset: number;
        };
        /** @description Statistics about stored World Bank debarred records. */
        WorldBankDebarredStatsResponse: {
            /** @description Total number of World Bank debarred entities in the database */
            total_entities?: number;
            /**
             * Format: date-time
             * @description Timestamp of the most recently updated record
             */
            last_updated?: string | null;
        };
        /** @description Request to start an EU Most Wanted fugitives crawl job. */
        EUMostWantedCrawlRequest: {
            /**
             * @description Whether to download and store photos to Garage storage
             * @default true
             */
            download_images: boolean;
        };
        /** @description EU Most Wanted fugitive details. */
        EUMostWantedFugitiveResponse: {
            /**
             * Format: uuid
             * @description Internal database ID
             */
            id: string;
            /** @description Drupal node ID (e.g., "2057") */
            node_id: string;
            /** @description Full name in "SURNAME, Given Names" format */
            full_name: string;
            /** @description Detail page URL slug (e.g., "/omar-abdifatah-yahye") */
            url_slug: string;
            /** @description Wanted status (Wanted or Arrested) */
            status: string;
            /** @description Country that issued the warrant (e.g., "Sweden") */
            wanted_by_country: string;
            /** @description Array of crime categories */
            crimes: string[];
            /** @description Gender (extracted from raw_data) */
            gender?: string | null;
            /** @description Date of birth (extracted from raw_data) */
            date_of_birth?: string | null;
            /** @description Nationalities (extracted from raw_data) */
            nationality?: string[] | null;
            /** @description Case description (extracted from raw_data) */
            description?: string | null;
            /** @description Garage object storage path for photo */
            image_path?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Paginated list of EU Most Wanted fugitives. */
        EUMostWantedFugitiveListResponse: {
            items: components["schemas"]["EUMostWantedFugitiveResponse"][];
            /** @description Total number of matching fugitives */
            total: number;
            limit: number;
            offset: number;
        };
        CreateScheduleRequest: {
            crawler_type: components["schemas"]["CrawlerType"];
            /**
             * @description Crawler-specific parameters (same as job submission)
             * @example {
             *       "lpse_code": "kemenkeu",
             *       "tahun": "2026",
             *       "tender_type": "lelang",
             *       "max_pages": 50
             *     }
             */
            crawler_params: {
                [key: string]: unknown;
            };
            interval: components["schemas"]["ScheduleInterval"];
        };
        UpdateScheduleRequest: {
            /** @description Crawler-specific parameters */
            crawler_params: {
                [key: string]: unknown;
            };
            interval: components["schemas"]["ScheduleInterval"];
            status: components["schemas"]["ScheduleStatus"];
        };
        ScheduleResponse: {
            /** Format: uuid */
            id: string;
            crawler_type: string;
            crawler_params: {
                [key: string]: unknown;
            };
            interval: components["schemas"]["ScheduleInterval"];
            status: components["schemas"]["ScheduleStatus"];
            /** Format: date-time */
            next_scheduled_at?: string | null;
            /** Format: date-time */
            last_executed_at?: string | null;
            /** Format: uuid */
            last_execution_job_id?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        ScheduleListResponse: {
            schedules: components["schemas"]["ScheduleResponse"][];
            total: number;
        };
        SubmitResponse: {
            /** Format: uuid */
            job_id: string;
            status: string;
        };
        /**
         * @description A single log entry from job execution
         * @example {
         *       "ts": "2025-01-03T12:34:56.789Z",
         *       "level": "info",
         *       "message": "Processing page 5 of 10"
         *     }
         */
        LogEntry: {
            /**
             * Format: date-time
             * @description ISO 8601 timestamp of the log entry
             */
            ts: string;
            /**
             * @description Log severity level
             * @enum {string}
             */
            level: "error" | "warning" | "info" | "debug" | "progress";
            /** @description Log message content */
            message: string;
            /** @description Optional event type (e.g., "completed") */
            event?: string;
        } & {
            [key: string]: unknown;
        };
        /** @description Historical logs for a job */
        JobLogsResponse: {
            /** @description Log entries (newest first) */
            logs: components["schemas"]["LogEntry"][];
            /** @description Total number of logs (before filtering/pagination) */
            total: number;
        };
        JobResponse: {
            id: string;
            crawler_type: string;
            params: {
                [key: string]: unknown;
            };
            status: components["schemas"]["JobStatus"];
            error?: string | null;
            failure_class?: components["schemas"]["FailureClass"] | null;
            pages_crawled: number;
            items_extracted: number;
            /** @description Number of retry attempts made before reaching current status */
            retry_count?: number;
            /** Format: date-time */
            created_at?: string | null;
            /** Format: date-time */
            updated_at?: string | null;
            /** Format: date-time */
            started_at?: string | null;
            /** Format: date-time */
            completed_at?: string | null;
            /** @description Last 100 log entries for this job (newest first) */
            recent_logs?: components["schemas"]["LogEntry"][] | null;
            /**
             * @description Last successfully completed page (1-indexed) for checkpoint resume.
             *     NULL means no checkpoint (fresh start or completed).
             *     On retry, crawling resumes from page N+1.
             */
            last_completed_page?: number | null;
            /**
             * Format: uuid
             * @description ID of the recurring schedule that created this job, if any
             */
            schedule_id?: string | null;
            /**
             * Format: uuid
             * @description ID of the original job this was resumed from, if any
             */
            resumed_from_job_id?: string | null;
        };
        UpdateJobRequest: {
            /**
             * Format: date-time
             * @description The `updated_at` value last observed by the client.
             *     Used for optimistic concurrency; stale values return 409.
             */
            expected_updated_at: string;
            /** @description Updated crawler type. When changed, params are revalidated against the new crawler schema. */
            crawler_type?: string;
            /** @description Updated crawler parameters (without internal trace metadata). */
            params?: {
                [key: string]: unknown;
            };
            /**
             * @description Direct status correction for non-running jobs only.
             *     `running` is not an allowed target state.
             *     Terminal jobs cannot be moved back to `queued`; use retry/resume instead.
             */
            status?: components["schemas"]["JobStatus"];
            error?: string | null;
            failure_class?: components["schemas"]["FailureClass"] | null;
            pages_crawled?: number;
            items_extracted?: number;
            retry_count?: number;
            /** Format: date-time */
            started_at?: string | null;
            /** Format: date-time */
            completed_at?: string | null;
            /** @description Replace the stored log buffer for the job. */
            recent_logs?: components["schemas"]["LogEntry"][];
            last_completed_page?: number | null;
            /** Format: uuid */
            schedule_id?: string | null;
            /** Format: uuid */
            resumed_from_job_id?: string | null;
        };
        JobListResponse: {
            jobs: components["schemas"]["JobResponse"][];
            count: number;
        };
        CancelResponse: {
            job_id: string;
            action: string;
        };
        ResumeJobResponse: {
            /**
             * Format: uuid
             * @description ID of the newly created resume job
             */
            job_id: string;
            /**
             * Format: uuid
             * @description ID of the original failed/cancelled job
             */
            resumed_from_job_id: string;
            /** @description Page number the resumed job will start from */
            start_page: number;
            /** @description Crawler type of the job */
            crawler_type: string;
        };
        /** @enum {string} */
        FailureClass: "site_down" | "layout_changed" | "rate_limited" | "timeout" | "browser_crashed" | "data_quality" | "unknown";
        JobSummaryBucket: {
            crawler_type: string;
            status: components["schemas"]["JobStatus"];
            failure_class?: components["schemas"]["FailureClass"] | null;
            count: number;
        };
        JobSummaryResponse: {
            buckets: components["schemas"]["JobSummaryBucket"][];
            hours: number;
        };
        QueueStatsResponse: {
            /** @description Number of jobs in the Redis queue */
            queue_length: number;
            /** @description Number of jobs currently running */
            running_count: number;
            /** @description Number of jobs waiting to be processed */
            queued_count: number;
            /** @description Total number of completed jobs */
            completed_count: number;
            /** @description Total number of failed jobs */
            failed_count: number;
            /** @description Total number of cancelled jobs */
            cancelled_count: number;
        };
        /** @description Recent jobs grouped by crawler type */
        RecentJobsResponse: {
            /**
             * @description Map of crawler_type to list of recent jobs.
             *     Keys are crawler types (e.g., "spse_http", "bpk", "lkpp_blacklist").
             *     Values are arrays of recent JobResponse objects, newest first.
             * @example {
             *       "spse_http": [
             *         {
             *           "id": "123e4567-e89b-12d3-a456-426614174000",
             *           "crawler_type": "spse_http",
             *           "params": {
             *             "lpse_code": "jakarta",
             *             "tahun": "2025"
             *           },
             *           "status": "completed"
             *         }
             *       ],
             *       "bpk": [
             *         {
             *           "id": "987fcdeb-51a2-3bc4-d567-890123456789",
             *           "crawler_type": "bpk",
             *           "params": {
             *             "q": "anggaran",
             *             "tahun": 2024
             *           },
             *           "status": "completed"
             *         }
             *       ]
             *     }
             */
            crawlers: {
                [key: string]: components["schemas"]["JobResponse"][];
            };
        };
        TenderResponse: {
            id: number;
            kode_tender: string;
            nama_tender: string;
            tender_type: string;
            lpse_code: string;
            instansi?: string | null;
            satuan_kerja?: string | null;
            jenis_pengadaan?: string | null;
            metode_pengadaan?: string | null;
            tahun_anggaran?: string | null;
            /** Format: decimal */
            nilai_pagu?: string | null;
            /** Format: decimal */
            nilai_hps?: string | null;
            jenis_kontrak?: string | null;
            /** @default [] */
            lokasi_pekerjaan: string[];
            /** Format: date */
            tanggal_pembuatan?: string | null;
            tahap_saat_ini?: string | null;
            peserta_count?: number | null;
            /** @default [] */
            rup_codes: {
                [key: string]: unknown;
            }[];
            /** @default [] */
            peserta: {
                [key: string]: unknown;
            }[];
            /** @default [] */
            hasil_evaluasi: {
                [key: string]: unknown;
            }[];
            /** @default [] */
            pemenang: {
                [key: string]: unknown;
            }[];
            /** @default [] */
            pemenang_berkontrak: {
                [key: string]: unknown;
            }[];
            /** Format: uri */
            source_url: string;
            /** Format: uri */
            uraian_pdf_url?: string | null;
            uraian_pdf_storage_path?: string | null;
            /**
             * Format: uri
             * @description Pre-signed URL for downloading the PDF (valid for 1 hour)
             */
            uraian_pdf_download_url?: string | null;
            /** @default [] */
            jadwal: {
                [key: string]: unknown;
            }[];
            /** @description Business qualification class (Non Kecil, Kecil, Koperasi) */
            kualifikasi_usaha?: string | null;
            syarat_kualifikasi?: components["schemas"]["SyaratKualifikasi"];
            realisasi?: components["schemas"]["Realisasi"];
            /** @description Cancellation reason for failed/cancelled tenders */
            alasan_pembatalan?: string | null;
            /** @description Package status badge (Paket Gagal, Paket Dibatalkan, etc.) */
            status_paket?: string | null;
            /** @description Reserved for Orang Asli Papua (Papua affirmative action) */
            oap_khusus?: boolean | null;
            /** @description Swakelola executor type for self-managed procurement */
            tipe_pelaksana_swakelola?: string | null;
            /** @description Whether the tender uses e-reverse auction */
            reverse_auction?: boolean | null;
            /**
             * Format: decimal
             * @description Technical evaluation weight percentage (e.g., 80.0 means 80%)
             */
            bobot_teknis?: number | null;
            /**
             * Format: decimal
             * @description Cost evaluation weight percentage (e.g., 20.0 means 20%)
             */
            bobot_biaya?: number | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        TenderListResponse: {
            tenders: components["schemas"]["TenderResponse"][];
            total: number;
            limit: number;
            offset: number;
        };
        BlacklistEntryResponse: {
            id: string;
            sk_number: string;
            provider_name: string;
            provider_npwp?: string | null;
            provider_address?: string | null;
            status: string;
            /** Format: date-time */
            start_date?: string | null;
            /** Format: date-time */
            expired_date?: string | null;
            /** Format: date-time */
            publish_date?: string | null;
            tender?: {
                [key: string]: unknown;
            } | null;
            violation?: {
                [key: string]: unknown;
            } | null;
            correspondence?: {
                [key: string]: unknown;
            } | null;
            document?: {
                [key: string]: unknown;
            } | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        BlacklistListResponse: {
            entries: components["schemas"]["BlacklistEntryResponse"][];
            total: number;
            limit: number;
            offset: number;
        };
        PutusanResponse: {
            id: number;
            /** @description Unique ID from URL (alphanumeric, may have z-prefix) */
            putusan_id: string;
            /** @description Case number: '2416 K/PID.SUS/2025' */
            nomor: string;
            /** @description Court level: Pertama, Banding, Kasasi, Peninjauan Kembali */
            tingkat_proses?: string | null;
            /**
             * @description Classification tags: ['Pidana Khusus', 'Korupsi']
             * @default []
             */
            klasifikasi: string[];
            /**
             * @description Keywords if present
             * @default []
             */
            kata_kunci: string[];
            /** @description Year: '2025' */
            tahun?: string | null;
            /** @description MAHKAMAH AGUNG, PENGADILAN NEGERI, etc. */
            lembaga_peradilan?: string | null;
            /** @description MA, PN, PT, etc. */
            jenis_lembaga_peradilan?: string | null;
            /**
             * Format: date
             * @description Registration date
             */
            tanggal_register?: string | null;
            /**
             * Format: date
             * @description Deliberation date
             */
            tanggal_musyawarah?: string | null;
            /**
             * Format: date
             * @description Decision read date (primary sort field)
             */
            tanggal_dibacakan?: string | null;
            /** @description Chief judge name */
            hakim_ketua?: string | null;
            /**
             * @description Panel member judges
             * @default []
             */
            hakim_anggota: string[];
            /** @description Court clerk name */
            panitera?: string | null;
            /** @description Verdict: 'Tolak Perbaikan', 'Kabul', 'Bebas' */
            amar?: string | null;
            /** @description Additional verdict details */
            amar_lainnya?: string | null;
            /** @description Detailed verdict notes */
            catatan_amar?: string | null;
            /** @description 'Berkekuatan Hukum Tetap', etc. */
            status?: string | null;
            /** @description Legal principle */
            kaidah?: string | null;
            /** @description Abstract/summary */
            abstrak?: string | null;
            /**
             * Format: uri
             * @description PDF download URL
             */
            pdf_url?: string | null;
            /** @description Object storage path after upload */
            pdf_storage_path?: string | null;
            /**
             * Format: uri
             * @description Pre-signed URL for downloading the PDF (valid for 1 hour)
             */
            pdf_download_url?: string | null;
            /**
             * @description Related case links: {kasasi: {putusan_id, nomor, url}, ...}
             * @default {}
             */
            related_cases: {
                [key: string]: unknown;
            };
            /**
             * Format: uri
             * @description Source URL
             */
            source_url: string;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        PutusanListResponse: {
            putusans: components["schemas"]["PutusanResponse"][];
            total: number;
            limit: number;
            offset: number;
        };
        PutusanStatsResponse: {
            /** @description Total number of stored putusans */
            total_putusans: number;
            /** @description Count by court level: {Kasasi: 150, Banding: 80, ...} */
            by_tingkat_proses: {
                [key: string]: number;
            };
            /** @description Count by verdict: {Kabul: 100, Tolak: 200, ...} */
            by_amar: {
                [key: string]: number;
            };
            /** @description Count by year: {'2024': 500, '2025': 200, ...} */
            by_tahun: {
                [key: string]: number;
            };
        };
        SingaporeJudgmentResponse: {
            id: number;
            /** @description Unique citation: '[2025] SGHC 260' */
            citation: string;
            /** @description Case number: 'HC/CC 63/2025' */
            case_number?: string | null;
            /** @description Case title: 'Public Prosecutor v Gao Xiong' */
            case_title: string;
            /** @description Court name */
            court?: string | null;
            /** @description Court type: SGHC, SGDC, SGCA, SGFC, SGMC */
            court_type?: string | null;
            /**
             * Format: date
             * @description Decision date
             */
            decision_date?: string | null;
            /** @description Plaintiff name */
            plaintiff?: string | null;
            /** @description Defendant name */
            defendant?: string | null;
            /**
             * @description Legal catchwords/topics
             * @default []
             */
            catchwords: string[];
            /**
             * @description Judge names
             * @default []
             */
            judges: string[];
            /**
             * Format: uri
             * @description PDF download URL
             */
            pdf_url?: string | null;
            /** @description Object storage path after upload */
            pdf_storage_path?: string | null;
            /**
             * Format: uri
             * @description Pre-signed URL for downloading the PDF (valid for 1 hour)
             */
            pdf_download_url?: string | null;
            /** @description Full judgment text as markdown (only included for single judgment lookups) */
            content?: string | null;
            /**
             * Format: uri
             * @description Source URL
             */
            source_url: string;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        SingaporeJudgmentListResponse: {
            judgments: components["schemas"]["SingaporeJudgmentResponse"][];
            total: number;
            limit: number;
            offset: number;
        };
        SingaporeJudgmentStatsResponse: {
            /** @description Total number of stored judgments */
            total_judgments: number;
            /** @description Count of judgments by court type (e.g., SGHC: 150, SGCA: 80) */
            by_court_type: {
                [key: string]: number;
            };
            /** @description Count of judgments by year (e.g., 2024: 500, 2025: 200) */
            by_year: {
                [key: string]: number;
            };
        };
        /** @description SPRM offender metadata stored as JSONB */
        SPRMOffenderMetadata: {
            /** @description Offender name (Tertuduh) */
            accused?: string;
            /** @description ID number (No Pengenalan Diri) */
            id_number?: string | null;
            /** @description Gender (Jantina) */
            gender?: string | null;
            /** @description Nationality (Warganegara) */
            nationality?: string | null;
            /** @description Malaysian state (Negeri) */
            state?: string | null;
            /** @description Offense category (Kategory) */
            category?: string | null;
            /** @description Employer (Majikan) */
            employer?: string | null;
            /** @description Position (Jawatan) */
            position?: string | null;
            /** @description Court (Mahkamah) */
            court?: string | null;
            /** @description Judge (Hakim) */
            judge?: string | null;
            /** @description Prosecuting officer (Timbalan Pendakwa Raya / Pegawai Pendakwa) */
            officer?: string | null;
            /** @description Defense attorney (Peguam Bela) */
            defense_attorney?: string | null;
            /** @description Past convictions (Sabitan Lampau) */
            past_convictions?: string | null;
            /** @description Sentencing date (Tarikh Jatuh Hukuman) */
            sentencing_date?: string | null;
            /** @description Appeal status (Rayuan) */
            appeal?: string | null;
            /**
             * @description List of charges with details
             * @default []
             */
            charges: {
                number?: string | null;
                summary?: string | null;
                offenses?: string | null;
                punishments?: string | null;
            }[];
        };
        SPRMOffenderResponse: {
            /** @description SHA256 hash of URL#data-key */
            id: string;
            /**
             * Format: uri
             * @description Source URL
             */
            source_url: string;
            metadata: components["schemas"]["SPRMOffenderMetadata"];
            /** @description Raw site content (only included for single offender lookups) */
            site_content?: string | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        SPRMOffenderListResponse: {
            offenders: components["schemas"]["SPRMOffenderResponse"][];
            total: number;
            limit: number;
            offset: number;
        };
        SPRMOffenderStatsResponse: {
            /** @description Total number of stored offenders */
            total_offenders: number;
            /** @description Count by state (e.g., Selangor: 150, Johor: 80) */
            by_state: {
                [key: string]: number;
            };
            /** @description Count by category */
            by_category: {
                [key: string]: number;
            };
        };
        OpenTenderTenderResponse: {
            /** @description SHA256 hash of lpse_code#tender_id */
            id: string;
            /** @description Original tender ID from OpenTender API */
            tender_id: number;
            /** @description LPSE code */
            lpse_code: string;
            /**
             * Format: uri
             * @description Source API URL
             */
            source_url: string;
            /** @description Full tender data from OpenTender API (fiscal_year, package_name, winner_name, contract_final, etc.) */
            metadata: {
                [key: string]: unknown;
            };
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        OpenTenderTenderListResponse: {
            items: components["schemas"]["OpenTenderTenderResponse"][];
            /** @description Total count of matching tenders */
            total: number;
            /** @description Requested page size */
            limit: number;
            /** @description Requested offset */
            offset: number;
        };
        /** @description Full OCDS release from OpenTender.net API */
        OpentenderOcdsReleaseResponse: {
            /** @description SHA256 hash of ocid#release_id */
            id: string;
            /** @description Open Contracting ID */
            ocid: string;
            /** @description Release ID within the OCID */
            release_id: string;
            lpse_code: string;
            fiscal_year: string;
            buyer_name?: string | null;
            buyer_id?: string | null;
            tender_title?: string | null;
            tender_status?: string | null;
            tender_value_amount?: number | null;
            tender_currency?: string | null;
            /** Format: date-time */
            date_published?: string | null;
            procurement_category?: string | null;
            /** @description Full OCDS release JSON per https://standard.open-contracting.org/ */
            release_data: {
                [key: string]: unknown;
            };
            /** Format: uri */
            source_url: string;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        /** @description Summary of OCDS release for list responses */
        OpentenderOcdsReleaseSummary: {
            id: string;
            ocid: string;
            release_id?: string;
            lpse_code: string;
            fiscal_year: string;
            buyer_name?: string | null;
            tender_title?: string | null;
            tender_status?: string | null;
            tender_value_amount?: number | null;
            tender_currency?: string | null;
            /** Format: date-time */
            created_at: string;
        };
        OpentenderOcdsReleaseListResponse: {
            items: components["schemas"]["OpentenderOcdsReleaseSummary"][];
            /** @description Total count of matching releases */
            total: number;
            /** @description Requested page size */
            limit: number;
            /** @description Requested offset */
            offset: number;
        };
        /** @description BPK taxonomy data (types, themes, or subjects) */
        BPKTaxonomyResponse: {
            [key: string]: unknown;
        };
        OpentenderMasterLpse: {
            /** @description LPSE code used for API filtering */
            code: string;
            /** @description LPSE name (e.g., "LPSE Kota Surabaya") */
            name: string;
        };
        OpentenderMasterLpseCreateRequest: {
            code: string;
            name: string;
        };
        OpentenderMasterLpseUpdateRequest: {
            name?: string;
        };
        OpentenderMasterLpseListResponse: {
            items: components["schemas"]["OpentenderMasterLpse"][];
            /** @description Total number of LPSE units matching the applied search and filters */
            total: number;
            /** @description Max results returned in this page */
            limit: number;
            /** @description Pagination offset used for this page */
            offset: number;
        };
        OpentenderMasterInstansi: {
            /** @description Institution code */
            code: string;
            /** @description Institution name */
            name: string;
            /** @description Institution type (BUMN, BUMD, etc.) */
            type: string;
        };
        OpentenderMasterInstansiCreateRequest: {
            code: string;
            name: string;
            type: string;
        };
        OpentenderMasterInstansiUpdateRequest: {
            name?: string;
            type?: string;
        };
        OpentenderMasterInstansiListResponse: {
            items: components["schemas"]["OpentenderMasterInstansi"][];
            /** @description Total number of institutions matching the applied search and filters */
            total: number;
            /** @description Max results returned in this page */
            limit: number;
            /** @description Pagination offset used for this page */
            offset: number;
        };
        OpentenderMasterSkpd: {
            /** @description SKPD code */
            code: number;
            /** @description SKPD name */
            name: string;
            /** @description Alternative name */
            alt_name?: string | null;
            /** @description Associated LPSE code */
            lpse?: number | null;
            /** @description Associated LPSE name */
            lpse_name?: string | null;
        };
        OpentenderMasterSkpdCreateRequest: {
            code: number;
            name: string;
            alt_name?: string | null;
            lpse?: number | null;
            lpse_name?: string | null;
        };
        OpentenderMasterSkpdUpdateRequest: {
            name?: string;
            alt_name?: string | null;
            lpse?: number | null;
            lpse_name?: string | null;
        };
        OpentenderMasterSkpdListResponse: {
            items: components["schemas"]["OpentenderMasterSkpd"][];
            /** @description Total number of SKPD units matching the applied search and filters */
            total: number;
            /** @description Max results returned in this page */
            limit: number;
            /** @description Pagination offset used for this page */
            offset: number;
        };
        OpentenderMasterSourceFund: {
            /** @description Source fund key */
            key: number;
            /** @description Source fund label (APBN, APBD, BUMN, etc.) */
            label: string;
        };
        OpentenderMasterSourceFundCreateRequest: {
            key: number;
            label: string;
        };
        OpentenderMasterSourceFundUpdateRequest: {
            label?: string;
        };
        OpentenderMasterSourceFundListResponse: {
            items: components["schemas"]["OpentenderMasterSourceFund"][];
            /** @description Total number of funding sources matching the applied search and filters */
            total: number;
            /** @description Max results returned in this page */
            limit: number;
            /** @description Pagination offset used for this page */
            offset: number;
        };
        /** @description BPK regulation details */
        BpkRegulationResponse: {
            /** @description Database primary key */
            id: number;
            /** @description BPK regulation ID */
            regulation_id: string;
            slug: string;
            /** @description Regulation title */
            judul: string;
            judul_lengkap?: string | null;
            /** @description Regulation number */
            nomor?: string | null;
            /** @description Year (as string) */
            tahun?: string | null;
            bentuk?: string | null;
            /** @description Regulation type abbreviation (PP, Perpres, etc.) */
            bentuk_singkat?: string | null;
            tipe_dokumen?: string | null;
            /** @description Government entity (TEU) */
            teu?: string | null;
            subjek?: string | null;
            /** @description Status (Berlaku, Dicabut, Tidak Berlaku) */
            status?: string | null;
            /** Format: date */
            tanggal_penetapan?: string | null;
            /** Format: date */
            tanggal_pengundangan?: string | null;
            /** Format: date */
            tanggal_berlaku?: string | null;
            tempat_penetapan?: string | null;
            sumber?: string | null;
            lokasi?: string | null;
            bidang?: string | null;
            bahasa?: string | null;
            metadata?: {
                [key: string]: unknown;
            } | null;
            /** @description PDF file information */
            pdf_files?: {
                [key: string]: unknown;
            }[] | null;
            relations?: {
                [key: string]: unknown;
            } | null;
            uji_materi?: {
                [key: string]: unknown;
            }[] | null;
            /** Format: uri */
            source_url: string;
            keywords?: string[] | null;
            /**
             * @deprecated
             * @description DEPRECATED: Use 'metadata' field instead.
             *     This field is an alias for 'metadata' and will be removed in a future version.
             *     Both fields contain the same data - the full crawled regulation data as JSON.
             */
            raw_data?: {
                [key: string]: unknown;
            } | null;
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            updated_at: string;
        };
        BpkRegulationListResponse: {
            items: components["schemas"]["BpkRegulationResponse"][];
            /** @description Total count of matching regulations */
            total: number;
            /** @description Requested page size */
            limit: number;
            /** @description Requested offset */
            offset: number;
        };
        CrawlerStatusSummary: {
            crawler_type: string;
            display_name: string;
            /** @enum {string} */
            probe_type: "browser" | "api" | "curl";
            /** @enum {string} */
            health_status: "healthy" | "unhealthy" | "degraded" | "unknown";
            /** Format: date-time */
            last_checked_at?: string | null;
            consecutive_failures: number;
            last_error?: string | null;
            schedules_active: number;
            schedules_paused: number;
            jobs_last_24h: number;
            jobs_failed_last_24h: number;
            /** Format: date-time */
            last_successful_crawl_at?: string | null;
        };
        CrawlerStatusResponse: {
            crawlers: components["schemas"]["CrawlerStatusSummary"][];
            /** Format: date-time */
            checked_at: string;
        };
        ProbeResultResponse: {
            crawler_type: string;
            passed: boolean;
            failed_selectors?: string[] | null;
            error_message?: string | null;
            duration_ms: number;
        };
        ProbeQueuedResponse: {
            crawler_type: string;
            message: string;
        };
        JobSummary: {
            /** Format: uuid */
            id: string;
            status: components["schemas"]["JobStatus"];
            /** Format: date-time */
            created_at: string;
            /** Format: date-time */
            completed_at?: string | null;
            items_extracted: number;
            error?: string | null;
        };
        ScheduleSummary: {
            /** Format: uuid */
            id: string;
            interval: components["schemas"]["ScheduleInterval"];
            status: components["schemas"]["ScheduleStatus"];
            paused_reason?: string | null;
            /** Format: date-time */
            next_scheduled_at?: string | null;
        };
        CrawlerStatusDetailResponse: {
            crawler_type: string;
            display_name: string;
            /** @enum {string} */
            probe_type: "browser" | "api" | "curl";
            /** @enum {string} */
            health_status: "healthy" | "unhealthy" | "degraded" | "unknown";
            /** Format: date-time */
            last_checked_at?: string | null;
            consecutive_failures: number;
            last_error?: string | null;
            failed_selectors?: string[] | null;
            duration_ms?: number | null;
            schedules_active: number;
            schedules_paused: number;
            jobs_last_24h: number;
            jobs_failed_last_24h: number;
            /** Format: date-time */
            last_successful_crawl_at?: string | null;
            recent_jobs: components["schemas"]["JobSummary"][];
            schedules: components["schemas"]["ScheduleSummary"][];
        };
        ErrorResponse: {
            detail: string;
        };
    };
    responses: {
        /** @description Bad request - invalid input */
        BadRequest: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/json": components["schemas"]["ErrorResponse"];
            };
        };
        /** @description Resource not found */
        NotFound: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/json": components["schemas"]["ErrorResponse"];
            };
        };
        /** @description Unauthorized - API key missing or invalid */
        Unauthorized: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/json": components["schemas"]["ErrorResponse"];
            };
        };
        /** @description Validation error */
        ValidationError: {
            headers: {
                [name: string]: unknown;
            };
            content: {
                "application/json": components["schemas"]["ErrorResponse"];
            };
        };
        /** @description Service unavailable (queue full or unavailable) */
        ServiceUnavailable: {
            headers: {
                /** @description Suggested retry delay in seconds */
                "Retry-After"?: string;
                [name: string]: unknown;
            };
            content: {
                "application/json": components["schemas"]["ErrorResponse"];
            };
        };
    };
    parameters: never;
    requestBodies: never;
    headers: never;
    pathItems: never;
};
export type $defs = Record<string, never>;
export interface operations {
    healthCheck: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Service is healthy */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": {
                        /**
                         * @description Health status indicator
                         * @example ok
                         */
                        status: string;
                    };
                };
            };
        };
    };
    submitSpseHttpCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SPSEHttpCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitSpseHttpBatchCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SPSEHttpBatchCrawlRequest"];
            };
        };
        responses: {
            /** @description Jobs created (check individual items for failures) */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SPSEBatchJobResult"][];
                };
            };
            /** @description Invalid request (duplicate tender_types, duplicate years in tahun_list, or both tahun and tahun_list provided). */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listLpseSites: {
        parameters: {
            query?: {
                /** @description Search by code, name, base URL, region, email, type, status, or SPSE version */
                q?: string;
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of available LPSE sites */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LPSESiteListResponse"];
                };
            };
        };
    };
    createLpseSite: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["LPSESiteCreateRequest"];
            };
        };
        responses: {
            /** @description LPSE site created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LPSESite"];
                };
            };
            /** @description LPSE site code already exists */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
        };
    };
    getLpseSite: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description LPSE site code (e.g., 'polri-archive', 'jakarta') */
                code: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description LPSE site details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LPSESite"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    deleteLpseSite: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description LPSE site code */
                code: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description LPSE site deleted */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            404: components["responses"]["NotFound"];
        };
    };
    updateLpseSite: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description LPSE site code */
                code: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["LPSESiteUpdateRequest"];
            };
        };
        responses: {
            /** @description LPSE site updated */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["LPSESite"];
                };
            };
            404: components["responses"]["NotFound"];
            422: components["responses"]["ValidationError"];
        };
    };
    submitBpkCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["BPKCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitLkppBlacklistCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["LKPPBlacklistCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitMahkamahAgungCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["MahkamahAgungCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitMahkamahAgungPdfDownload: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["MahkamahAgungPdfRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    queryPutusans: {
        parameters: {
            query?: {
                /** @description Search in nomor (case number) */
                keyword?: string;
                /** @description Filter by court level: Pertama, Banding, Kasasi, Peninjauan Kembali */
                tingkat_proses?: string;
                /** @description Filter by verdict: Kabul, Tolak, Bebas, etc. */
                amar?: string;
                /** @description Filter by year */
                tahun?: string;
                /** @description Filter by court institution: MAHKAMAH AGUNG, PENGADILAN NEGERI, etc. */
                lembaga_peradilan?: string;
                /** @description Filter by chief judge name */
                hakim_ketua?: string;
                /** @description Sort field */
                sort_by?: "tanggal_dibacakan" | "tanggal_register" | "nomor" | "tahun" | "created_at" | "updated_at";
                /** @description Sort order */
                sort_order?: "asc" | "desc";
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Putusan list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PutusanListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getPutusan: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Putusan ID (alphanumeric, may have z-prefix) */
                putusan_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Putusan details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PutusanResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getPutusanStats: {
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
                    "application/json": components["schemas"]["PutusanStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitSingaporeCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SingaporeCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    querySingaporeJudgments: {
        parameters: {
            query?: {
                /** @description Search in citation or case_title */
                keyword?: string;
                /** @description Filter by court type: SGHC, SGDC, SGCA, SGFC, SGMC */
                court_type?: string;
                /** @description Filter by decision year */
                year?: number;
                /** @description Sort field */
                sort_by?: "decision_date" | "citation" | "case_title" | "created_at";
                /** @description Sort order */
                sort_order?: "asc" | "desc";
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Judgment list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SingaporeJudgmentListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getSingaporeJudgment: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Judgment citation (e.g., '[2025] SGHC 260') */
                citation: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Judgment details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SingaporeJudgmentResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getSingaporeJudgmentStats: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Statistics retrieved successfully */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SingaporeJudgmentStatsResponse"];
                };
            };
            401: components["responses"]["Unauthorized"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitSprmCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SPRMCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    querySprmOffenders: {
        parameters: {
            query?: {
                /** @description Filter by Malaysian state (e.g., Selangor, Johor) */
                state?: string;
                /** @description Filter by offense category */
                category?: string;
                /** @description Sort field */
                sort_by?: "created_at";
                /** @description Sort order */
                sort_order?: "asc" | "desc";
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Offender list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SPRMOffenderListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getSprmOffender: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Offender ID (SHA256 hash) */
                offender_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Offender details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SPRMOffenderResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getSprmOffenderStats: {
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
                    "application/json": components["schemas"]["SPRMOffenderStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitOpenTenderCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpenTenderCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitOpenTenderOcdsCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpenTenderOcdsCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    queryOpenTenderTenders: {
        parameters: {
            query?: {
                /** @description Filter by LPSE code (e.g., "10" for Surabaya) */
                lpse_code?: string;
                /** @description Filter by fiscal year (e.g., "2024") */
                fiscal_year?: string;
                /** @description Filter by category label */
                category?: string;
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Tender list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpenTenderTenderListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getOpenTenderTender: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Tender ID (SHA256 hash of lpse_code#tender_id) */
                tender_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Tender details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpenTenderTenderResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    queryOpentenderOcdsReleases: {
        parameters: {
            query?: {
                /** @description Filter by LPSE regional code */
                lpse_code?: string;
                /** @description Filter by fiscal year (e.g., "2024") */
                fiscal_year?: string;
                /** @description Filter by buyer name (case-insensitive contains) */
                buyer_name?: string;
                /** @description Filter by tender status */
                tender_status?: "planning" | "active" | "complete" | "cancelled" | "unsuccessful";
                /** @description Filter by Open Contracting ID */
                ocid?: string;
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of OCDS releases */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderOcdsReleaseListResponse"];
                };
            };
            /** @description Invalid query parameters */
            400: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getOpentenderOcdsReleaseById: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Release ID (SHA256 hash of ocid#release_id) */
                release_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description OCDS release details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderOcdsReleaseResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getOpentenderMasterLpse: {
        parameters: {
            query?: {
                /** @description Search by LPSE code or name */
                q?: string;
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of LPSE units */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterLpseListResponse"];
                };
            };
        };
    };
    createOpentenderMasterLpse: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpentenderMasterLpseCreateRequest"];
            };
        };
        responses: {
            /** @description LPSE unit created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterLpse"];
                };
            };
            /** @description LPSE code already exists */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
        };
    };
    getOpentenderMasterLpseByCode: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description LPSE code */
                code: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description LPSE unit */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterLpse"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    deleteOpentenderMasterLpse: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description LPSE code */
                code: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description LPSE unit deleted */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            404: components["responses"]["NotFound"];
        };
    };
    updateOpentenderMasterLpse: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description LPSE code */
                code: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpentenderMasterLpseUpdateRequest"];
            };
        };
        responses: {
            /** @description LPSE unit updated */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterLpse"];
                };
            };
            404: components["responses"]["NotFound"];
            422: components["responses"]["ValidationError"];
        };
    };
    getOpentenderMasterInstansi: {
        parameters: {
            query?: {
                /** @description Search by institution code, name, or type */
                q?: string;
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of institutions */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterInstansiListResponse"];
                };
            };
        };
    };
    createOpentenderMasterInstansi: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpentenderMasterInstansiCreateRequest"];
            };
        };
        responses: {
            /** @description Institution created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterInstansi"];
                };
            };
            /** @description Institution code already exists */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
        };
    };
    getOpentenderMasterInstansiByCode: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Institution code */
                code: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Institution */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterInstansi"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    deleteOpentenderMasterInstansi: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Institution code */
                code: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Institution deleted */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            404: components["responses"]["NotFound"];
        };
    };
    updateOpentenderMasterInstansi: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Institution code */
                code: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpentenderMasterInstansiUpdateRequest"];
            };
        };
        responses: {
            /** @description Institution updated */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterInstansi"];
                };
            };
            404: components["responses"]["NotFound"];
            422: components["responses"]["ValidationError"];
        };
    };
    getOpentenderMasterSkpd: {
        parameters: {
            query?: {
                /** @description Filter by LPSE code */
                lpse?: number;
                /** @description Search by SKPD code, name, alternate name, or LPSE. Must contain at least 3 non-whitespace characters. */
                q?: string;
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of SKPD units */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterSkpdListResponse"];
                };
            };
        };
    };
    createOpentenderMasterSkpd: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpentenderMasterSkpdCreateRequest"];
            };
        };
        responses: {
            /** @description SKPD unit created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterSkpd"];
                };
            };
            /** @description SKPD code already exists */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
        };
    };
    getOpentenderMasterSkpdByCode: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description SKPD code */
                code: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description SKPD unit */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterSkpd"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    deleteOpentenderMasterSkpd: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description SKPD code */
                code: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description SKPD unit deleted */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            404: components["responses"]["NotFound"];
        };
    };
    updateOpentenderMasterSkpd: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description SKPD code */
                code: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpentenderMasterSkpdUpdateRequest"];
            };
        };
        responses: {
            /** @description SKPD unit updated */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterSkpd"];
                };
            };
            404: components["responses"]["NotFound"];
            422: components["responses"]["ValidationError"];
        };
    };
    getOpentenderMasterSourceFund: {
        parameters: {
            query?: {
                /** @description Search by source-fund key or label */
                q?: string;
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of funding sources */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterSourceFundListResponse"];
                };
            };
        };
    };
    createOpentenderMasterSourceFund: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpentenderMasterSourceFundCreateRequest"];
            };
        };
        responses: {
            /** @description Source fund created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterSourceFund"];
                };
            };
            /** @description Source-fund key already exists */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
        };
    };
    getOpentenderMasterSourceFundByKey: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Source-fund key */
                key: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Source fund */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterSourceFund"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    deleteOpentenderMasterSourceFund: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Source-fund key */
                key: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Source fund deleted */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            404: components["responses"]["NotFound"];
        };
    };
    updateOpentenderMasterSourceFund: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Source-fund key */
                key: number;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["OpentenderMasterSourceFundUpdateRequest"];
            };
        };
        responses: {
            /** @description Source fund updated */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["OpentenderMasterSourceFund"];
                };
            };
            404: components["responses"]["NotFound"];
            422: components["responses"]["ValidationError"];
        };
    };
    submitSirupCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SubmitSirupCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    querySirupPaket: {
        parameters: {
            query: {
                /** @description Budget year (required) */
                tahun_anggaran: number;
                /** @description Filter by package type */
                package_type?: "penyedia" | "swakelola";
                /** @description Max results per page */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Package list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SirupPaketListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getSirupPaket: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description RUP code (kode_rup) */
                kode_rup: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Package details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SirupPaketResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitInterpolCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["InterpolCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listInterpolNotices: {
        parameters: {
            query?: {
                /** @description Filter by nationality code (e.g., "ID" for Indonesia) */
                nationality?: string;
                /** @description Filter by wanting country code (e.g., "US") */
                wanted_by?: string;
                /** @description Search by family name or forename (ILIKE pattern match) */
                name?: string;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of Red Notices */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["InterpolNoticeListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getInterpolNotice: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Interpol notice ID (e.g., "2025-96936") */
                entity_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Red Notice details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["InterpolNoticeResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getInterpolStats: {
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
                    "application/json": components["schemas"]["InterpolStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitUkCompaniesHouseCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["UkCompaniesHouseCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listUkDisqualifiedOfficers: {
        parameters: {
            query?: {
                /** @description Filter by officer type */
                officer_type?: "natural" | "corporate";
                /** @description Filter by nationality (natural persons only) */
                nationality?: string;
                /** @description Only return officers with active (non-expired) disqualifications */
                active_only?: boolean;
                /** @description Search by name (surname, forename, or company name). Uses ILIKE pattern match. */
                q?: string;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of disqualified officers */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["UkDisqualifiedOfficerListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getUkDisqualifiedOfficer: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Companies House officer ID (e.g., "Q8J9tnY4wzC8BP9ilhung2VFw8I") */
                officer_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Officer details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["UkDisqualifiedOfficerResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getUkCompaniesHouseStats: {
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
                    "application/json": components["schemas"]["UkCompaniesHouseStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitSgMasCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["SgMasCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listSgMasEnforcementActions: {
        parameters: {
            query?: {
                /** @description Filter by enforcement action type (e.g., "Prohibition Order", "Civil Penalty") */
                action_type?: string;
                /** @description Search by title (ILIKE pattern match) */
                q?: string;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of enforcement actions */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SgMasEnforcementActionListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getSgMasEnforcementAction: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Internal database UUID */
                id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Enforcement action details with full content */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SgMasEnforcementActionDetailResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getSgMasStats: {
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
                    "application/json": components["schemas"]["SgMasStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitScMalaysiaCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["ScMalaysiaCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listScAobSanctions: {
        parameters: {
            query?: {
                /** @description Filter by sanction year */
                year?: number;
                /** @description Search by auditor name (ILIKE pattern match) */
                q?: string;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of AOB sanctions */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ScAobSanctionListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getScAobSanctionsStats: {
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
                    "application/json": components["schemas"]["ScAobSanctionStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getScAobSanction: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Internal database UUID */
                id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description AOB sanction details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ScAobSanctionDetailResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listScInvestorAlerts: {
        parameters: {
            query?: {
                /** @description Filter by entity type (e.g., "individual", "entity") */
                entity_type?: string;
                /** @description Search by name (ILIKE pattern match) */
                q?: string;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of investor alerts */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ScInvestorAlertListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getScInvestorAlertsStats: {
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
                    "application/json": components["schemas"]["ScInvestorAlertStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getScInvestorAlert: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Internal database UUID */
                id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Investor alert details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ScInvestorAlertDetailResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listAdbSanctions: {
        parameters: {
            query?: {
                /** @description Filter by nationality */
                nationality?: string;
                /** @description Filter by sanction type (e.g. Debarred) */
                sanction_type?: string;
                /** @description Filter by inferred entity type */
                entity_type?: "company" | "person";
                /** @description Filter by active/lapsed status */
                is_active?: boolean;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of ADB sanctions */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdbSanctionListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitAdbSanctionsCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["AdbSanctionsCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getAdbSanctionsStats: {
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
                    "application/json": components["schemas"]["AdbSanctionStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getAdbSanction: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description ADB record ID (24-character hex string) */
                adb_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description ADB sanction details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["AdbSanctionDetailResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listPpatkDttot: {
        parameters: {
            query?: {
                /** @description Filter by PPATK entity type */
                entity_type?: "Orang" | "Korporasi";
                /** @description Filter by nationality */
                nationality?: string;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of PPATK DTTOT entities */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PpatkDttotListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitPpatkDttotCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["PpatkDttotCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getPpatkDttotStats: {
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
                    "application/json": components["schemas"]["PpatkDttotStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getPpatkDttotByDensusCode: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Densus code (for example IDD-032) */
                densus_code: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description PPATK DTTOT entity details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["PpatkDttotDetailResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listWorldBankDebarred: {
        parameters: {
            query?: {
                /** @description Filter by country name */
                country_name?: string;
                /** @description Filter by inferred entity type */
                entity_type?: "company" | "person";
                /** @description Filter by indefinite debarment status */
                is_indefinite?: boolean;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of World Bank debarred records */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["WorldBankDebarredListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitWorldBankDebarredCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["WorldBankDebarredCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getWorldBankDebarredStats: {
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
                    "application/json": components["schemas"]["WorldBankDebarredStatsResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getWorldBankDebarredRecord: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description World Bank supplier ID */
                supp_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description World Bank debarred record details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["WorldBankDebarredDetailResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    submitEUMostWantedCrawl: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["EUMostWantedCrawlRequest"];
            };
        };
        responses: {
            /** @description Job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["SubmitResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listEUMostWantedFugitives: {
        parameters: {
            query?: {
                /** @description Filter by wanted-by country (e.g., "Sweden") */
                country?: string;
                /** @description Search by full name (ILIKE pattern match) */
                name?: string;
                /** @description Maximum number of results to return */
                limit?: number;
                /** @description Number of results to skip for pagination */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of fugitives */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["EUMostWantedFugitiveListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getEUMostWantedFugitive: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Drupal node ID (e.g., "2057") */
                node_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Fugitive details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["EUMostWantedFugitiveResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    listJobs: {
        parameters: {
            query?: {
                /** @description Maximum number of jobs to return */
                limit?: number;
                /** @description Filter by job status */
                status?: components["schemas"]["JobStatus"];
                /** @description Filter by crawler type */
                crawler_type?: string;
                /** @description Only return jobs created within the last N hours */
                hours?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Job list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["JobListResponse"];
                };
            };
        };
    };
    getJobSummary: {
        parameters: {
            query?: {
                hours?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Aggregated job counts by crawler type, status, and failure class */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["JobSummaryResponse"];
                };
            };
        };
    };
    getQueueStats: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Queue stats */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["QueueStatsResponse"];
                };
            };
        };
    };
    getRecentJobsPerCrawler: {
        parameters: {
            query?: {
                /** @description Maximum number of jobs to return per crawler type */
                limit?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Recent jobs grouped by crawler type */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["RecentJobsResponse"];
                };
            };
        };
    };
    getJobStatus: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                job_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Job details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["JobResponse"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    updateJob: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                job_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["UpdateJobRequest"];
            };
        };
        responses: {
            /** @description Updated job details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["JobResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            /** @description Job update conflict (running job, stale update, or unsupported status target) */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
            422: components["responses"]["ValidationError"];
        };
    };
    cancelJob: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                job_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Cancel requested */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CancelResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            422: components["responses"]["ValidationError"];
        };
    };
    resumeJob: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                job_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Resume job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ResumeJobResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            /** @description Job cannot be resumed (wrong state or active resume exists) */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    retryJob: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                job_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Retry job created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["JobResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            /** @description Job cannot be retried in its current state */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    streamJobLogs: {
        parameters: {
            query: {
                /** @description API key for authentication (required since EventSource doesn't support headers) */
                api_key: string;
            };
            header?: never;
            path: {
                /** @description Job UUID to stream logs for */
                job_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description SSE stream of log events */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "text/event-stream": string;
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            /** @description Too many concurrent streams */
            503: {
                headers: {
                    /** @description Seconds to wait before retrying */
                    "Retry-After"?: number;
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    getJobLogs: {
        parameters: {
            query?: {
                /** @description Filter logs by level */
                level?: "error" | "warning" | "info" | "debug" | "progress";
                /** @description Maximum number of logs to return */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path: {
                /** @description Job UUID to get logs for */
                job_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Log entries */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["JobLogsResponse"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    listSchedules: {
        parameters: {
            query?: {
                /** @description Filter by schedule status */
                status?: components["schemas"]["ScheduleStatus"];
                /** @description Maximum number of schedules to return */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description List of schedules */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ScheduleListResponse"];
                };
            };
            401: components["responses"]["Unauthorized"];
        };
    };
    createSchedule: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["CreateScheduleRequest"];
            };
        };
        responses: {
            /** @description Schedule created */
            201: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ScheduleResponse"];
                };
            };
            400: components["responses"]["BadRequest"];
            401: components["responses"]["Unauthorized"];
            422: components["responses"]["ValidationError"];
        };
    };
    getSchedule: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Schedule UUID */
                schedule_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Schedule details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ScheduleResponse"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    deleteSchedule: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Schedule UUID */
                schedule_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Schedule deleted */
            204: {
                headers: {
                    [name: string]: unknown;
                };
                content?: never;
            };
            404: components["responses"]["NotFound"];
            /** @description Cannot delete schedule with running job */
            409: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    updateSchedule: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Schedule UUID */
                schedule_id: string;
            };
            cookie?: never;
        };
        requestBody: {
            content: {
                "application/json": components["schemas"]["UpdateScheduleRequest"];
            };
        };
        responses: {
            /** @description Schedule updated */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ScheduleResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            422: components["responses"]["ValidationError"];
        };
    };
    getCrawlerStatus: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Crawler status overview */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CrawlerStatusResponse"];
                };
            };
            401: components["responses"]["Unauthorized"];
        };
    };
    getCrawlerStatusDetail: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Crawler type (e.g., spse, bpk, lkpp_blacklist) */
                crawler_type: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Crawler status detail */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["CrawlerStatusDetailResponse"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
        };
    };
    triggerProbe: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Crawler type to probe (e.g., spse, bpk, lkpp_blacklist) */
                crawler_type: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Probe result (API/curl probes executed inline) */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ProbeResultResponse"];
                };
            };
            /** @description Probe queued for execution by the worker (browser probes) */
            202: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ProbeQueuedResponse"];
                };
            };
            401: components["responses"]["Unauthorized"];
            404: components["responses"]["NotFound"];
            /** @description Probe ran recently, try again later */
            429: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["ErrorResponse"];
                };
            };
        };
    };
    queryTenders: {
        parameters: {
            query?: {
                /** @description Filter by LPSE code */
                lpse_code?: string;
                /** @description Filter by tender type */
                tender_type?: string;
                /** @description Minimum budget ceiling */
                min_nilai_pagu?: string;
                /** @description Fiscal year filter (partial match) */
                tahun_anggaran?: string;
                /** @description Filter by PDF presence */
                has_pdf?: boolean;
                /** @description Max results */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Tender list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TenderListResponse"];
                };
            };
        };
    };
    getTender: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                tender_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Tender details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["TenderResponse"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    queryBlacklistEntries: {
        parameters: {
            query?: {
                /** @description Search by provider name (partial match) */
                provider_name?: string;
                /** @description Filter by status (PUBLISHED, CANCELLED, etc.) */
                status?: string;
                /** @description Max results */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Blacklist entries */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BlacklistListResponse"];
                };
            };
        };
    };
    getBlacklistEntry: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                entry_id: string;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Blacklist entry */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BlacklistEntryResponse"];
                };
            };
            404: components["responses"]["NotFound"];
        };
    };
    getBpkTypes: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Regulation types */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BPKTaxonomyResponse"];
                };
            };
        };
    };
    getBpkThemes: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Themes */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BPKTaxonomyResponse"];
                };
            };
        };
    };
    getBpkSubjects: {
        parameters: {
            query?: never;
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Subjects */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BPKTaxonomyResponse"];
                };
            };
        };
    };
    queryBpkRegulations: {
        parameters: {
            query?: {
                /** @description Filter by year (e.g., 2024) */
                tahun?: string;
                /** @description Filter by regulation status */
                status?: "Berlaku" | "Dicabut" | "Tidak Berlaku";
                /** @description Maximum results to return */
                limit?: number;
                /** @description Pagination offset */
                offset?: number;
            };
            header?: never;
            path?: never;
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Regulation list */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BpkRegulationListResponse"];
                };
            };
            503: components["responses"]["ServiceUnavailable"];
        };
    };
    getBpkRegulation: {
        parameters: {
            query?: never;
            header?: never;
            path: {
                /** @description Regulation database ID */
                regulation_id: number;
            };
            cookie?: never;
        };
        requestBody?: never;
        responses: {
            /** @description Regulation details */
            200: {
                headers: {
                    [name: string]: unknown;
                };
                content: {
                    "application/json": components["schemas"]["BpkRegulationResponse"];
                };
            };
            404: components["responses"]["NotFound"];
            503: components["responses"]["ServiceUnavailable"];
        };
    };
}
