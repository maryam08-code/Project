--
-- PostgreSQL database dump
--

\restrict aZdQZjk2hGAFY8SzQIhj3rXMWzztNPhRGhBLsdZqVUKEgV2bWuDhBMFT2XazY36

-- Dumped from database version 18.4 (Ubuntu 18.4-1.pgdg24.04+1)
-- Dumped by pg_dump version 18.4 (Ubuntu 18.4-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: archive_source_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.archive_source_type AS ENUM (
    'letter_request',
    'incoming_letter',
    'outgoing_letter',
    'disposition'
);


ALTER TYPE public.archive_source_type OWNER TO postgres;

--
-- Name: disposition_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.disposition_status AS ENUM (
    'dikirim',
    'diterima',
    'ditindaklanjuti',
    'selesai'
);


ALTER TYPE public.disposition_status OWNER TO postgres;

--
-- Name: document_owner_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.document_owner_type AS ENUM (
    'letter_request',
    'incoming_letter',
    'outgoing_letter',
    'disposition_follow_up',
    'archive',
    'backup'
);


ALTER TYPE public.document_owner_type OWNER TO postgres;

--
-- Name: follow_up_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.follow_up_status AS ENUM (
    'proses',
    'selesai'
);


ALTER TYPE public.follow_up_status OWNER TO postgres;

--
-- Name: incoming_letter_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.incoming_letter_status AS ENUM (
    'diregistrasi',
    'diteruskan',
    'didisposisikan',
    'ditindaklanjuti',
    'selesai'
);


ALTER TYPE public.incoming_letter_status OWNER TO postgres;

--
-- Name: letter_request_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.letter_request_status AS ENUM (
    'draft',
    'dikirim',
    'diproses_operator',
    'menunggu_approval',
    'disetujui',
    'ditolak',
    'selesai'
);


ALTER TYPE public.letter_request_status OWNER TO postgres;

--
-- Name: notification_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_type AS ENUM (
    'letter_request_submitted',
    'incoming_letter_forwarded',
    'disposition_created',
    'disposition_followed_up',
    'letter_request_approved',
    'letter_request_rejected',
    'outgoing_letter_sent',
    'generic'
);


ALTER TYPE public.notification_type OWNER TO postgres;

--
-- Name: outgoing_letter_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.outgoing_letter_status AS ENUM (
    'draft',
    'diperiksa',
    'menunggu_approval',
    'disetujui',
    'ditolak',
    'dikirim'
);


ALTER TYPE public.outgoing_letter_status OWNER TO postgres;

--
-- Name: priority_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.priority_level AS ENUM (
    'biasa',
    'penting',
    'segera'
);


ALTER TYPE public.priority_level OWNER TO postgres;

--
-- Name: user_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_status AS ENUM (
    'aktif',
    'nonaktif'
);


ALTER TYPE public.user_status OWNER TO postgres;

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: archives; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.archives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    archive_number character varying(60) NOT NULL,
    source_type public.archive_source_type NOT NULL,
    source_id uuid NOT NULL,
    document_id uuid,
    letter_type_id uuid,
    subject character varying(255) NOT NULL,
    status character varying(80) NOT NULL,
    archived_by uuid,
    archived_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.archives OWNER TO postgres;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    activity character varying(120) NOT NULL,
    module character varying(80) NOT NULL,
    data_id uuid,
    data_label character varying(180),
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    review_status character varying(40) DEFAULT NULL::character varying,
    review_notes text,
    reviewed_by uuid,
    reviewed_at timestamp with time zone
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: backups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    backup_code character varying(80) NOT NULL,
    document_id uuid,
    status character varying(40) DEFAULT 'success'::character varying NOT NULL,
    file_size_bytes bigint,
    notes text,
    executed_by uuid,
    executed_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.backups OWNER TO postgres;

--
-- Name: disposition_follow_ups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.disposition_follow_ups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    disposition_id uuid NOT NULL,
    notes text NOT NULL,
    status public.follow_up_status DEFAULT 'proses'::public.follow_up_status NOT NULL,
    followed_up_by uuid NOT NULL,
    followed_up_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.disposition_follow_ups OWNER TO postgres;

--
-- Name: dispositions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dispositions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    disposition_number character varying(60) NOT NULL,
    incoming_letter_id uuid NOT NULL,
    giver_id uuid NOT NULL,
    target_user_id uuid,
    target_unit_id uuid,
    instruction text NOT NULL,
    due_date date,
    priority public.priority_level DEFAULT 'biasa'::public.priority_level NOT NULL,
    status public.disposition_status DEFAULT 'dikirim'::public.disposition_status NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    received_at timestamp with time zone,
    followed_up_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT dispositions_target_required CHECK (((target_user_id IS NOT NULL) OR (target_unit_id IS NOT NULL)))
);


ALTER TABLE public.dispositions OWNER TO postgres;

--
-- Name: documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    owner_type public.document_owner_type NOT NULL,
    owner_id uuid,
    original_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    storage_path text NOT NULL,
    mime_type character varying(150) NOT NULL,
    file_extension character varying(20) NOT NULL,
    file_size_bytes bigint NOT NULL,
    checksum_sha256 character varying(64),
    previewable boolean DEFAULT false NOT NULL,
    uploaded_by uuid,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT documents_allowed_extension CHECK ((lower((file_extension)::text) = ANY (ARRAY['pdf'::text, 'doc'::text, 'docx'::text, 'jpg'::text, 'jpeg'::text, 'png'::text, 'dump'::text, 'sql'::text]))),
    CONSTRAINT documents_allowed_mime CHECK (((mime_type)::text = ANY ((ARRAY['application/pdf'::character varying, 'application/msword'::character varying, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'::character varying, 'image/jpeg'::character varying, 'image/png'::character varying, 'application/octet-stream'::character varying])::text[]))),
    CONSTRAINT documents_file_size_bytes_check CHECK (((file_size_bytes > 0) AND (file_size_bytes <= 10485760)))
);


ALTER TABLE public.documents OWNER TO postgres;

--
-- Name: email_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    direction character varying(20) NOT NULL,
    message_id text,
    mailbox character varying(120),
    sender text,
    recipients text[] DEFAULT '{}'::text[] NOT NULL,
    cc text[] DEFAULT '{}'::text[] NOT NULL,
    subject character varying(255) NOT NULL,
    text_body text,
    html_body text,
    attachment_metadata jsonb DEFAULT '[]'::jsonb NOT NULL,
    related_module character varying(80),
    related_id uuid,
    provider_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    received_at timestamp with time zone,
    sent_at timestamp with time zone,
    synced_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    process_status character varying(30) DEFAULT 'belum_diproses'::character varying NOT NULL,
    processed_at timestamp with time zone,
    processed_by uuid,
    processing_error text,
    CONSTRAINT email_messages_direction_check CHECK (((direction)::text = ANY ((ARRAY['incoming'::character varying, 'outgoing'::character varying])::text[]))),
    CONSTRAINT email_messages_process_status_check CHECK (((process_status)::text = ANY ((ARRAY['belum_diproses'::character varying, 'sudah_diproses'::character varying])::text[])))
);


ALTER TABLE public.email_messages OWNER TO postgres;

--
-- Name: incoming_letters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.incoming_letters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agenda_number character varying(60) NOT NULL,
    letter_number character varying(100) NOT NULL,
    letter_date date NOT NULL,
    received_date date NOT NULL,
    sender character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    letter_type_id uuid NOT NULL,
    letter_nature_id uuid NOT NULL,
    summary text,
    status public.incoming_letter_status DEFAULT 'diregistrasi'::public.incoming_letter_status NOT NULL,
    registered_by uuid NOT NULL,
    forwarded_to uuid,
    forwarded_by uuid,
    forwarded_at timestamp with time zone,
    read_by_leader_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.incoming_letters OWNER TO postgres;

--
-- Name: letter_natures; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.letter_natures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(80) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.letter_natures OWNER TO postgres;

--
-- Name: letter_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.letter_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_number character varying(60) NOT NULL,
    request_date date DEFAULT CURRENT_DATE NOT NULL,
    letter_type_id uuid NOT NULL,
    subject character varying(255) NOT NULL,
    destination character varying(255) NOT NULL,
    body text NOT NULL,
    applicant_id uuid NOT NULL,
    applicant_unit_id uuid,
    status public.letter_request_status DEFAULT 'draft'::public.letter_request_status NOT NULL,
    operator_id uuid,
    approver_id uuid,
    rejection_note text,
    submitted_at timestamp with time zone,
    processed_at timestamp with time zone,
    approval_requested_at timestamp with time zone,
    approved_at timestamp with time zone,
    rejected_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT letter_requests_rejection_note_required CHECK (((status <> 'ditolak'::public.letter_request_status) OR (rejection_note IS NOT NULL)))
);


ALTER TABLE public.letter_requests OWNER TO postgres;

--
-- Name: letter_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.letter_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(120) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.letter_types OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recipient_id uuid NOT NULL,
    type public.notification_type DEFAULT 'generic'::public.notification_type NOT NULL,
    title character varying(180) NOT NULL,
    message text NOT NULL,
    source_type character varying(80),
    source_id uuid,
    is_read boolean DEFAULT false NOT NULL,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: outgoing_letters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.outgoing_letters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    letter_number character varying(100) NOT NULL,
    letter_date date NOT NULL,
    letter_type_id uuid,
    destination character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    summary text,
    status public.outgoing_letter_status DEFAULT 'draft'::public.outgoing_letter_status NOT NULL,
    created_by uuid NOT NULL,
    checked_by uuid,
    approver_id uuid,
    rejection_note text,
    sent_method character varying(80),
    sent_reference character varying(120),
    checked_at timestamp with time zone,
    approval_requested_at timestamp with time zone,
    approved_at timestamp with time zone,
    rejected_at timestamp with time zone,
    sent_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT outgoing_letters_rejection_note_required CHECK (((status <> 'ditolak'::public.outgoing_letter_status) OR (rejection_note IS NOT NULL)))
);


ALTER TABLE public.outgoing_letters OWNER TO postgres;

--
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(100) NOT NULL,
    name character varying(150) NOT NULL,
    module character varying(80) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_permissions (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.role_permissions OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    id bigint NOT NULL,
    filename character varying(255) NOT NULL,
    checksum_sha256 character varying(64) NOT NULL,
    executed_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: schema_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schema_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.schema_migrations_id_seq OWNER TO postgres;

--
-- Name: schema_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schema_migrations_id_seq OWNED BY public.schema_migrations.id;


--
-- Name: units; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.units OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_id uuid NOT NULL,
    unit_id uuid,
    full_name character varying(150) NOT NULL,
    username character varying(80) NOT NULL,
    email public.citext,
    password_hash text NOT NULL,
    "position" character varying(120),
    phone character varying(40),
    address text,
    status public.user_status DEFAULT 'aktif'::public.user_status NOT NULL,
    must_change_password boolean DEFAULT false NOT NULL,
    last_login_at timestamp with time zone,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: schema_migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations ALTER COLUMN id SET DEFAULT nextval('public.schema_migrations_id_seq'::regclass);


--
-- Data for Name: archives; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.archives (id, archive_number, source_type, source_id, document_id, letter_type_id, subject, status, archived_by, archived_at, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, activity, module, data_id, data_label, metadata, ip_address, user_agent, created_at, review_status, review_notes, reviewed_by, reviewed_at) FROM stdin;
fffb2c91-215a-4230-b395-be8da5f6f043	6f23cb44-06f6-4c22-a3be-7a6fe4517572	seed_database	system	\N	Initial PostgreSQL schema seed	{"roles": 4, "timezone": "Asia/Jakarta"}	\N	\N	2026-06-02 15:53:44.826739+07	\N	\N	\N	\N
08b995c9-5e72-4f5f-9010-9da88c2847bf	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	node	2026-06-02 16:32:35.377703+07	\N	\N	\N	\N
d0353f86-072b-4254-99e0-a6b863c42abb	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	c0040bda-b8bc-4fff-a2e9-78fde204afc7	Asep Test	{}	::ffff:127.0.0.1	node	2026-06-02 16:32:35.413176+07	valid	Verified OK via API Test	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-02 16:32:35.428396+07
a4cee8c0-19e3-4340-b6e7-4536366f0d9b	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	d0353f86-072b-4254-99e0-a6b863c42abb	Review create_user (users)	{}	::ffff:127.0.0.1	node	2026-06-02 16:32:35.430221+07	\N	\N	\N	\N
00c75c8d-d9c2-4f7b-b50a-2de1bd48dbbb	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database_failed	backups	\N	\N	{"error": "new row for relation \\"documents\\" violates check constraint \\"documents_allowed_extension\\""}	::ffff:127.0.0.1	node	2026-06-02 16:32:35.572275+07	\N	\N	\N	\N
0ae3fea7-0ec0-4145-8e5f-8a2fe3fa6b4b	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:08.336265+07	valid	Verified OK via API Test	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-02 16:33:08.372716+07
99d16edb-77a1-4900-90d4-f5f243703506	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	0ae3fea7-0ec0-4145-8e5f-8a2fe3fa6b4b	Review login (auth)	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:08.374331+07	\N	\N	\N	\N
a29ed519-c49f-4140-adb1-fa6b443c18a3	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:18.848096+07	valid	Verified OK via API Test	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-02 16:33:18.881982+07
ca51f4b1-6b2b-4743-936e-94cbd2df138b	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	a29ed519-c49f-4140-adb1-fa6b443c18a3	Review login (auth)	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:18.883609+07	\N	\N	\N	\N
b31c5b6a-4daa-44ff-b80a-f2e635c1d867	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	66862295-fb8d-4348-a3ef-0376cacf5d98	BKP-2026-0602-1633	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:18.986296+07	\N	\N	\N	\N
2b18c13a-7cfe-42a8-a124-4c54e4d626d2	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:24.575748+07	\N	\N	\N	\N
b2dcdbfd-3958-4e81-9acb-3387002784de	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	e40af09e-843a-4aa4-9f6d-f7d68d486bf7	Asep Test	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:24.601858+07	\N	\N	\N	\N
5ff93d6a-2002-4aee-9332-4a9e4aadfa2f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	e40af09e-843a-4aa4-9f6d-f7d68d486bf7	Asep Test	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:24.614397+07	valid	Verified OK via API Test	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-02 16:33:24.624862+07
bcfe089a-4a3e-4683-91df-14f3bc6da39f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	5ff93d6a-2002-4aee-9332-4a9e4aadfa2f	Review reset_password (users)	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:24.626714+07	\N	\N	\N	\N
e1625c8d-0896-46be-9a05-bd054f5b9b85	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	e40af09e-843a-4aa4-9f6d-f7d68d486bf7	Asep Test	{}	::ffff:127.0.0.1	node	2026-06-02 16:33:24.636933+07	\N	\N	\N	\N
4f1b1b4d-d7dd-40e4-8eaa-bab5cee5e364	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	node	2026-06-04 13:35:48.694877+07	\N	\N	\N	\N
559488e6-f297-4293-b957-1fb7289c70a8	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	03cc6aa9-a5aa-4d08-ac89-bf04460d9f37	Asep Test	{}	::ffff:127.0.0.1	node	2026-06-04 13:35:48.730175+07	\N	\N	\N	\N
f93f21a8-7c8b-4b55-99eb-69959b5371f7	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	03cc6aa9-a5aa-4d08-ac89-bf04460d9f37	Asep Test	{}	::ffff:127.0.0.1	node	2026-06-04 13:35:48.741194+07	valid	Verified OK via API Test	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-04 13:35:48.751871+07
21cb7b0d-745d-4e4f-986d-749be64d546a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	f93f21a8-7c8b-4b55-99eb-69959b5371f7	Review reset_password (users)	{}	::ffff:127.0.0.1	node	2026-06-04 13:35:48.753267+07	\N	\N	\N	\N
5891d4a0-06dd-4f4d-88eb-48a30dc953a2	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	5dadee72-7642-4dae-bb34-5886f828580d	BKP-2026-0604-1335	{}	::ffff:127.0.0.1	node	2026-06-04 13:35:48.890851+07	\N	\N	\N	\N
c3a338f4-0348-45fd-a4bd-305c12651d70	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	03cc6aa9-a5aa-4d08-ac89-bf04460d9f37	Asep Test	{}	::ffff:127.0.0.1	node	2026-06-04 13:35:49.279716+07	\N	\N	\N	\N
4a528c28-5759-4665-bbc1-056aa419e9a2	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-06-04 13:37:18.912904+07	\N	\N	\N	\N
c12f8234-548e-4051-9efe-6f3d7b0a5b23	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	ea882088-79c4-4722-b64d-aebc68f8f79a	Mochamad Farhan Ali	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-06-04 13:38:31.831562+07	\N	\N	\N	\N
3aa5047b-df3a-4878-8ec3-62cfa7c0e8a6	6f23cb44-06f6-4c22-a3be-7a6fe4517572	logout	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-06-04 13:38:44.029326+07	\N	\N	\N	\N
0a5207ce-4262-4f50-9712-7f8b82d49600	ea882088-79c4-4722-b64d-aebc68f8f79a	login	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-06-04 13:48:32.534601+07	\N	\N	\N	\N
122b50ed-f451-4517-9562-c4cae15948c3	ea882088-79c4-4722-b64d-aebc68f8f79a	backup_database	backups	f4eca5d6-546a-4671-a87f-7d52518d9d88	BKP-2026-0604-1349	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-06-04 13:49:08.915781+07	\N	\N	\N	\N
61821dc1-c02b-4a86-88d3-873ca67f8329	ea882088-79c4-4722-b64d-aebc68f8f79a	logout	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-06-04 14:12:55.003244+07	\N	\N	\N	\N
b5e8c2d2-334b-416a-8bd3-a26753407328	76a563a6-e955-4544-b2cd-db0183fc3c6a	login	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-06-04 14:13:17.745838+07	\N	\N	\N	\N
293120e7-645a-4f7d-8b38-edab4ef9e8ac	76a563a6-e955-4544-b2cd-db0183fc3c6a	logout	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-06-04 14:13:41.102315+07	\N	\N	\N	\N
1fedf361-b1e8-4403-a4ff-e570c0c8d99a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:01:53.880229+07	\N	\N	\N	\N
6a3c99dc-1dc6-45ad-af84-42190a7896bf	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:10:17.513864+07	\N	\N	\N	\N
12a50b26-b5ed-4402-9522-e7e5880e5750	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	a295cb6f-588b-4468-ab13-a296bfcb21b5	BKP-2026-0617-1610	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:10:46.766694+07	\N	\N	\N	\N
65f286db-37d2-4526-9470-59a7f2c09fa4	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	a295cb6f-588b-4468-ab13-a296bfcb21b5	BKP-2026-0617-1610	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:10:49.996938+07	\N	\N	\N	\N
6b629cf2-b7ad-407b-ab09-564c4dd10c5a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:34:44.411278+07	\N	\N	\N	\N
02638e82-8be6-4d33-83c5-240cfb192b2f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:34:55.071532+07	\N	\N	\N	\N
a86f07ae-1a17-42ca-9c6c-b89ce602faa8	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator E-Office Test	{}	::ffff:127.0.0.1	\N	2026-06-17 16:34:55.088562+07	\N	\N	\N	\N
209065fb-8a0c-41d5-80a3-6c043a9a01ee	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Super Admin	{}	::ffff:127.0.0.1	\N	2026-06-17 16:34:55.098677+07	\N	\N	\N	\N
c1318edb-41f3-4afe-b5b8-cbeee224d73d	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Farhan Ali	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:37:03.147987+07	\N	\N	\N	\N
e17a001f-5119-486c-8f2d-387fb4799cff	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:37:08.158214+07	\N	\N	\N	\N
97748c69-079a-4ef7-838d-458cc67e191e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	24c835b2-ad6a-41eb-ba19-797483ae5aac	BKP-2026-0617-1637	{}	::ffff:127.0.0.1	\N	2026-06-17 16:37:08.310975+07	\N	\N	\N	\N
44745b3b-95c2-4245-82f8-86cf1c993ab2	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	24c835b2-ad6a-41eb-ba19-797483ae5aac	BKP-2026-0617-1637	{}	::ffff:127.0.0.1	\N	2026-06-17 16:37:08.314696+07	\N	\N	\N	\N
2e72ad24-c032-4f70-b20a-2178cda67533	6f23cb44-06f6-4c22-a3be-7a6fe4517572	logout	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:37:09.521974+07	\N	\N	\N	\N
b4bafcaf-1073-4ddb-9340-092b1c84dac3	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:37:13.362618+07	\N	\N	\N	\N
23af7368-a170-4deb-91c9-a0b0764e024a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Farhan Ali	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:37:29.699163+07	\N	\N	\N	\N
e7651dcc-ba11-4743-b5e0-0c50b6da3da1	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:38:39.478883+07	\N	\N	\N	\N
ff9a65df-7d9b-4c38-9e05-2ae60b656397	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	d28c5883-eb4c-4095-8bc7-0da92fc43a0d	User Testing CRUD	{}	::ffff:127.0.0.1	\N	2026-06-17 16:38:39.496504+07	\N	\N	\N	\N
f0a4f410-8845-436a-ab29-d4a4edf3dd77	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	d28c5883-eb4c-4095-8bc7-0da92fc43a0d	User Testing CRUD Updated	{}	::ffff:127.0.0.1	\N	2026-06-17 16:38:39.502297+07	\N	\N	\N	\N
0619928d-4191-4004-b17e-d848be94122c	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	d28c5883-eb4c-4095-8bc7-0da92fc43a0d	User Testing CRUD Updated	{}	::ffff:127.0.0.1	\N	2026-06-17 16:38:39.511888+07	\N	\N	\N	\N
44cd9da9-cae6-4dd3-805c-d0672d241b29	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	d28c5883-eb4c-4095-8bc7-0da92fc43a0d	User Testing CRUD Updated	{}	::ffff:127.0.0.1	\N	2026-06-17 16:38:39.517197+07	\N	\N	\N	\N
3b906932-71b6-465b-a8f5-487308fa31f4	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	ea882088-79c4-4722-b64d-aebc68f8f79a	Mochamad Farhan Ali	{}	::1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	2026-06-17 16:50:26.007839+07	\N	\N	\N	\N
feef6a4f-99d7-4bc9-bbb1-62ccbebe265e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:09.398843+07	\N	\N	\N	\N
468ae81c-b559-4378-8eaf-be77af82993f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	2fcdac58-d028-4dc1-bfda-42a8ed0e767c	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:09.41294+07	\N	\N	\N	\N
0df74b3e-cb00-4d15-914c-7fe3cba3d34e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	2fcdac58-d028-4dc1-bfda-42a8ed0e767c	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:09.425668+07	\N	\N	\N	\N
81605849-6871-4fde-868b-f28e2b1ed999	2fcdac58-d028-4dc1-bfda-42a8ed0e767c	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:09.434632+07	\N	\N	\N	\N
08d70c81-28e4-4de9-b536-5b6771e11c9b	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	2fcdac58-d028-4dc1-bfda-42a8ed0e767c	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:09.443785+07	\N	\N	\N	\N
d9fad0bf-502c-4904-9f45-f061be4715a3	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	2fcdac58-d028-4dc1-bfda-42a8ed0e767c	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:09.452296+07	\N	\N	\N	\N
2525dc1c-5df7-4371-9c69-58e6c660780b	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator System	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:09.459331+07	\N	\N	\N	\N
2e8306c0-9298-445d-9f8f-f5d1154370c7	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	bf6bcb90-18e7-462b-b22e-45ad35706a95	BKP-2026-0617-1652	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:09.588754+07	\N	\N	\N	\N
d7267c3f-7144-4719-a9bf-b5ab044f55ec	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:58.123569+07	\N	\N	\N	\N
6ead1d83-4d7d-407e-a1b9-014785485398	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator System	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:58.153503+07	valid	Reviewed by automated test suite	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:52:58.168551+07
d27b1f82-0944-43bd-9d6d-0dc38e5d48f2	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	6ead1d83-4d7d-407e-a1b9-014785485398	Review update_user (users)	{}	::ffff:127.0.0.1	\N	2026-06-17 16:52:58.171058+07	\N	\N	\N	\N
8ffc123f-e5d6-4053-a2ee-edfbd0646dec	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.362852+07	\N	\N	\N	\N
a0d50c85-9389-473c-b22e-aa5760e0562f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	84affe69-87f4-44f9-830b-a82e33ca5cd5	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.377163+07	\N	\N	\N	\N
16c7d0d4-4f4b-4efa-a526-15a6d2d77445	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	84affe69-87f4-44f9-830b-a82e33ca5cd5	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.390508+07	\N	\N	\N	\N
c527b490-d143-41f7-a787-01b7745d54bd	84affe69-87f4-44f9-830b-a82e33ca5cd5	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.399507+07	\N	\N	\N	\N
6e1ab5cf-1f38-4a49-b864-f2928b8f3737	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	84affe69-87f4-44f9-830b-a82e33ca5cd5	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.416877+07	\N	\N	\N	\N
96c82619-3b1d-43e7-a6c7-703d84305d4e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator System	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.424308+07	\N	\N	\N	\N
3653f4c1-282c-4552-a6a3-35de84f45cb9	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	3779f08a-3b1f-4791-8e26-24f2ea7b99e9	BKP-2026-0617-1653	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.58239+07	\N	\N	\N	\N
3962379b-f4f8-4d40-86b6-d4ef9b65935d	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	3779f08a-3b1f-4791-8e26-24f2ea7b99e9	BKP-2026-0617-1653	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.587066+07	valid	Reviewed by automated test suite	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:53:36.872347+07
8e6ff9e5-3338-4fd6-a5b8-4a243743d083	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	3962379b-f4f8-4d40-86b6-d4ef9b65935d	Review download_backup (backups)	{}	::ffff:127.0.0.1	\N	2026-06-17 16:53:36.873398+07	\N	\N	\N	\N
a4578628-022b-44dd-abac-63d598520bb6	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.158373+07	\N	\N	\N	\N
a3f2e8ac-e5b9-43db-8fcf-439a55f8acc6	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	4e143772-e8c8-4fa1-bf8b-e84252874aae	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.170956+07	\N	\N	\N	\N
239292c4-45f1-441b-a6d9-c283dcb9da01	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	4e143772-e8c8-4fa1-bf8b-e84252874aae	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.181756+07	\N	\N	\N	\N
e9bc21fe-086a-4058-85b7-298c8acb2d0d	4e143772-e8c8-4fa1-bf8b-e84252874aae	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.189333+07	\N	\N	\N	\N
963419a3-d1dc-4b40-8c56-68a845807d23	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	4e143772-e8c8-4fa1-bf8b-e84252874aae	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.195454+07	\N	\N	\N	\N
4fdd654c-25ae-4945-94b0-d43f2a65b7c2	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	4e143772-e8c8-4fa1-bf8b-e84252874aae	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.202364+07	\N	\N	\N	\N
9b8e5970-e02f-41bf-b9f1-91e9f442333d	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator System	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.208018+07	\N	\N	\N	\N
2101f013-0088-477a-b225-7f15ffe61675	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	e8f7402f-20ed-4eee-aa73-feec11ddc49d	BKP-2026-0617-1654	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.320012+07	\N	\N	\N	\N
ea199b8e-6751-4e8c-abc8-5277a2024b9e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	e8f7402f-20ed-4eee-aa73-feec11ddc49d	BKP-2026-0617-1654	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.322974+07	valid	Reviewed by automated test suite	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:54:34.57868+07
5669db92-67ea-4d56-a352-8313bbd695ea	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	ea199b8e-6751-4e8c-abc8-5277a2024b9e	Review download_backup (backups)	{}	::ffff:127.0.0.1	\N	2026-06-17 16:54:34.579734+07	\N	\N	\N	\N
18c20f25-fab9-454a-be76-2a02a6ca7a31	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.313175+07	\N	\N	\N	\N
c790e707-5c04-4469-890f-ad8235730ff1	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	99ec6477-da63-4145-93ec-9f89c1053c2f	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.328784+07	\N	\N	\N	\N
a8c2bd8a-b48b-4b23-9438-949d375a6c43	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	99ec6477-da63-4145-93ec-9f89c1053c2f	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.33992+07	\N	\N	\N	\N
72f83c8c-9455-4c5b-a921-0160a7c6d4ac	99ec6477-da63-4145-93ec-9f89c1053c2f	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.347331+07	\N	\N	\N	\N
edf0d749-d470-42fd-85f7-767af4b8a72c	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	99ec6477-da63-4145-93ec-9f89c1053c2f	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.354842+07	\N	\N	\N	\N
4d5a7a46-1791-4b80-a49e-0eb175d5611c	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	99ec6477-da63-4145-93ec-9f89c1053c2f	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.361235+07	\N	\N	\N	\N
bacc9696-8026-4198-ba8a-d1fd3f9416b1	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator System	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.366998+07	\N	\N	\N	\N
83bc5fb5-9cf6-4ecc-9aa9-3094b6301a0b	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	8ac4271c-42cd-4c65-8122-4c9e3585f88b	BKP-2026-0709-2354	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.520087+07	\N	\N	\N	\N
0b69bc73-58af-4e90-baa3-5a758807f179	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	8ac4271c-42cd-4c65-8122-4c9e3585f88b	BKP-2026-0709-2354	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.523503+07	valid	Reviewed by automated test suite	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-09 23:54:54.75656+07
78473b25-a897-44cf-aa08-dae0bd758b8e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	review_audit_log	audit-logs	0b69bc73-58af-4e90-baa3-5a758807f179	Review download_backup (backups)	{}	::ffff:127.0.0.1	\N	2026-07-09 23:54:54.757391+07	\N	\N	\N	\N
54f13fa1-959e-4556-b350-a679bb161cdd	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-09 23:58:49.847969+07	\N	\N	\N	\N
0a00dfaf-6e31-431d-b3f6-07f01c2b7b21	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:40.885224+07	\N	\N	\N	\N
f7bb436f-2776-46f5-861f-898d1217effd	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	25f7a7e0-0ac9-412e-985a-0d400f78360d	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:40.896169+07	\N	\N	\N	\N
232c11c7-b2ce-46c7-992d-8f57f35cb8f2	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	25f7a7e0-0ac9-412e-985a-0d400f78360d	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:40.907956+07	\N	\N	\N	\N
52b055d9-7096-46d1-840b-c89b2bad8d1d	25f7a7e0-0ac9-412e-985a-0d400f78360d	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:40.916268+07	\N	\N	\N	\N
3fdd8750-e0e6-4884-aa29-58552dfac5a5	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	25f7a7e0-0ac9-412e-985a-0d400f78360d	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:40.925207+07	\N	\N	\N	\N
8a730cef-dca6-41c9-ac66-dfdc40dc73ac	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	25f7a7e0-0ac9-412e-985a-0d400f78360d	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:40.932382+07	\N	\N	\N	\N
96a122ec-2b22-4110-a80f-3f0531163f43	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator System	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:40.940408+07	\N	\N	\N	\N
01bbf855-edec-4a37-867c-02fd5d957a97	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	984d0615-595d-4b14-88b0-7af6454bdf03	BKP-2026-0710-0003	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:41.073256+07	\N	\N	\N	\N
c0022657-84e0-4de8-98ae-e359b06f1631	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	984d0615-595d-4b14-88b0-7af6454bdf03	BKP-2026-0710-0003	{}	::ffff:127.0.0.1	\N	2026-07-10 00:03:41.078169+07	\N	\N	\N	\N
31edee2c-d369-4115-970d-e8291969a58f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-07-10 00:05:38.367834+07	\N	\N	\N	\N
054aa555-b8e0-47a1-8f55-400d26a66d34	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	75bde822-d996-4d1a-8133-86bec399d61b	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-07-10 00:05:38.376108+07	\N	\N	\N	\N
ac07e568-2757-4251-83ea-c1e307ea2fad	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	75bde822-d996-4d1a-8133-86bec399d61b	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-07-10 00:05:38.384923+07	\N	\N	\N	\N
e4a75867-344a-4863-853e-c7d83998f604	75bde822-d996-4d1a-8133-86bec399d61b	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-07-10 00:05:38.391772+07	\N	\N	\N	\N
006de038-1549-465e-be9b-9a4d74d8512e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	75bde822-d996-4d1a-8133-86bec399d61b	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-07-10 00:05:38.39784+07	\N	\N	\N	\N
587dff62-b28b-432b-bccc-b7b3af1042f5	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	75bde822-d996-4d1a-8133-86bec399d61b	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-07-10 00:05:38.403451+07	\N	\N	\N	\N
3fb44aab-eb60-45bf-a960-5983a64aa1ed	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator System	{}	::ffff:127.0.0.1	\N	2026-07-10 00:05:38.409135+07	\N	\N	\N	\N
a4f03e0a-b96c-4f8c-bd94-aa7af8f192a5	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.758269+07	\N	\N	\N	\N
36af839b-284f-4cb6-a0a3-f4bea2844fbe	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	ad9ae71b-9f71-470e-a45f-9a7e6955b91d	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.76893+07	\N	\N	\N	\N
9ffacc3a-e076-4385-a8c0-d55c945b9a26	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	ad9ae71b-9f71-470e-a45f-9a7e6955b91d	Test Auditor	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.780556+07	\N	\N	\N	\N
60b445d8-a286-4612-8986-2ebdf550de8d	ad9ae71b-9f71-470e-a45f-9a7e6955b91d	login	auth	\N	\N	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.787971+07	\N	\N	\N	\N
9f24e25b-2764-485a-8d74-fee905a77b0b	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	ad9ae71b-9f71-470e-a45f-9a7e6955b91d	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.794969+07	\N	\N	\N	\N
0672a3e0-0c7d-47d2-b641-d48212fdabef	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	ad9ae71b-9f71-470e-a45f-9a7e6955b91d	Test Auditor Updated	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.800724+07	\N	\N	\N	\N
4b233381-0f2e-445b-bb44-f8de3581e69e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	6f23cb44-06f6-4c22-a3be-7a6fe4517572	Administrator System	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.806229+07	\N	\N	\N	\N
27a6b1b7-b6be-426d-802d-5e65f6037076	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	6b85a1e7-3b1d-479a-b45d-80e86f714a5e	BKP-2026-0710-0006	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.912488+07	\N	\N	\N	\N
a555781e-d382-4fde-b6ab-a9bac24507b8	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	6b85a1e7-3b1d-479a-b45d-80e86f714a5e	BKP-2026-0710-0006	{}	::ffff:127.0.0.1	\N	2026-07-10 00:06:23.915336+07	\N	\N	\N	\N
e3891eec-4f66-414a-af5c-5b849ba07bf0	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:09:00.240404+07	\N	\N	\N	\N
4f3208b3-cef7-4a03-81f1-9301b3a44e7a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	node	2026-07-10 00:11:54.400523+07	\N	\N	\N	\N
46384a12-2186-43a6-a24e-a0b4c537e2c1	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	node	2026-07-10 00:12:06.623113+07	\N	\N	\N	\N
4ac34833-79df-409b-a434-8c4019ae2933	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	node	2026-07-10 00:12:22.404421+07	\N	\N	\N	\N
cda77098-9f9a-41d1-9b92-a307d0c6e06b	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	4c24312e-275a-4f30-b10a-3fc248b4597c	Test User	{}	::ffff:127.0.0.1	node	2026-07-10 00:12:22.421056+07	\N	\N	\N	\N
6bece8ac-056f-4b31-8f52-ed6e39e3365e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	4c24312e-275a-4f30-b10a-3fc248b4597c	Test User	{}	::ffff:127.0.0.1	node	2026-07-10 00:12:22.426962+07	\N	\N	\N	\N
b397b864-9ad0-4540-8929-e338fa7eaa27	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	b502db56-2778-456a-bef2-e941d7496d0c	BKP-2026-0710-0016	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:16:46.298054+07	\N	\N	\N	\N
5d2c2dbf-d4fb-4787-80a1-d1097b93c7ac	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	b502db56-2778-456a-bef2-e941d7496d0c	BKP-2026-0710-0016	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:16:53.899344+07	\N	\N	\N	\N
e9c1d9aa-5ad5-4eda-8414-4fc3b62999e8	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	c0040bda-b8bc-4fff-a2e9-78fde204afc7	Asep Test	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:24:35.935697+07	\N	\N	\N	\N
02aa1092-ce64-4c16-963a-f06c7413dc91	6f23cb44-06f6-4c22-a3be-7a6fe4517572	backup_database	backups	99b98576-7cf0-4467-ad64-ff42afc43d1d	BKP-2026-0710-0025	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:25:23.448381+07	\N	\N	\N	\N
014691c3-b5a7-4a20-b443-f773dd46b47a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	download_backup	backups	99b98576-7cf0-4467-ad64-ff42afc43d1d	BKP-2026-0710-0025	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:25:26.576732+07	\N	\N	\N	\N
57c700af-1846-4f95-aa48-0f08e9d4e091	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	4c24312e-275a-4f30-b10a-3fc248b4597c	Test User	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:28:44.260165+07	\N	\N	\N	\N
e6958566-5d9f-4fe9-bfbc-a181a8227699	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	4c24312e-275a-4f30-b10a-3fc248b4597c	Test User	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:21.514226+07	\N	\N	\N	\N
079a491a-31b7-45f2-b012-cd6caaf9bcb4	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	ad9ae71b-9f71-470e-a45f-9a7e6955b91d	Test Auditor Updated	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:26.660062+07	\N	\N	\N	\N
de1434b9-32d2-4cdc-baff-3038e99c0902	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	75bde822-d996-4d1a-8133-86bec399d61b	Test Auditor Updated	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:28.504628+07	\N	\N	\N	\N
ce9a9544-6c52-4d88-8c5c-7bfaf39df6a3	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	25f7a7e0-0ac9-412e-985a-0d400f78360d	Test Auditor Updated	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:30.467096+07	\N	\N	\N	\N
a78ace69-824e-43de-adfa-7e1a68a490a9	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	99ec6477-da63-4145-93ec-9f89c1053c2f	Test Auditor Updated	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:32.218519+07	\N	\N	\N	\N
6ffb3b4d-f232-4b2a-b5c8-8d6942636774	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	4e143772-e8c8-4fa1-bf8b-e84252874aae	Test Auditor Updated	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:34.221185+07	\N	\N	\N	\N
71e03d5c-3832-49b4-a25a-49e5de4de69d	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	84affe69-87f4-44f9-830b-a82e33ca5cd5	Test Auditor	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:36.374993+07	\N	\N	\N	\N
616f78ba-642b-4c7d-b143-46dcf9201fff	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	2fcdac58-d028-4dc1-bfda-42a8ed0e767c	Test Auditor Updated	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:38.348038+07	\N	\N	\N	\N
56739b13-758a-45fe-9ca7-ace0354745af	6f23cb44-06f6-4c22-a3be-7a6fe4517572	toggle_user_status	users	ea882088-79c4-4722-b64d-aebc68f8f79a	Mochamad Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:41.451696+07	\N	\N	\N	\N
b60de969-36a9-4bae-a91f-c0f2a1d522e5	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	03cc6aa9-a5aa-4d08-ac89-bf04460d9f37	Asep Test	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:44.949161+07	\N	\N	\N	\N
a3ff520a-d22e-4a19-9780-024e8a8385a3	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	e40af09e-843a-4aa4-9f6d-f7d68d486bf7	Asep Test	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:46.735129+07	\N	\N	\N	\N
47b8f8ed-088d-4da9-a941-2efdcef943d8	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	c0040bda-b8bc-4fff-a2e9-78fde204afc7	Asep Test	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:32:48.554922+07	\N	\N	\N	\N
0ef9ee9a-b1ee-4200-8d50-b3f60f16976e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	ea882088-79c4-4722-b64d-aebc68f8f79a	Mochamad Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:33:04.303918+07	\N	\N	\N	\N
e6d9f662-7b12-4936-b698-ae3919d800ff	6f23cb44-06f6-4c22-a3be-7a6fe4517572	logout	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:33:17.576565+07	\N	\N	\N	\N
97461ff8-bbc1-47ed-aed8-19312c1fee34	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:33:30.550754+07	\N	\N	\N	\N
c4d4a7a0-9ac8-4cd4-b36f-0f4c9325587a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	ea882088-79c4-4722-b64d-aebc68f8f79a	Mochamad Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:33:37.080953+07	\N	\N	\N	\N
034ecab4-cee7-44b3-8a9f-58c20b6d208e	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	72ef88d7-60ef-458a-8af6-5f862c1796ec	123	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:35:08.451399+07	\N	\N	\N	\N
632f4882-9233-45d1-8138-e7400821273a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	logout	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:35:14.018816+07	\N	\N	\N	\N
9169ea37-cfba-4170-8eb4-ea49504ca426	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:35:26.65928+07	\N	\N	\N	\N
56f8874e-3e94-4db9-bf48-32bd3bc5a633	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	72ef88d7-60ef-458a-8af6-5f862c1796ec	123	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:35:53.891719+07	\N	\N	\N	\N
02aa37c9-82a9-48df-a534-5c957b258e9d	6f23cb44-06f6-4c22-a3be-7a6fe4517572	create_user	users	aad21b18-5924-4b9e-ba42-bccd18ff3713	Mochamad Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:15.959437+07	\N	\N	\N	\N
1501c3df-c662-42e3-8229-72947a23dd55	6f23cb44-06f6-4c22-a3be-7a6fe4517572	logout	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:19.305938+07	\N	\N	\N	\N
96da5bea-0fbe-4868-b0e8-613f37634e33	aad21b18-5924-4b9e-ba42-bccd18ff3713	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:22.343756+07	\N	\N	\N	\N
42df44d2-ed5d-422a-a73f-252e9d66da21	aad21b18-5924-4b9e-ba42-bccd18ff3713	logout	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:25.793844+07	\N	\N	\N	\N
20b6f5fb-350b-41f7-905e-d41b3512cc34	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:28.838282+07	\N	\N	\N	\N
7622dd63-b177-4b29-919e-ceb4cc9de11f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	update_user	users	aad21b18-5924-4b9e-ba42-bccd18ff3713	Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:43.342067+07	\N	\N	\N	\N
b596ad76-5df2-4ca2-a644-835694428f1a	6f23cb44-06f6-4c22-a3be-7a6fe4517572	toggle_user_status	users	aad21b18-5924-4b9e-ba42-bccd18ff3713	Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:49.374102+07	\N	\N	\N	\N
9ff63af3-736c-4f5e-82c6-870eca60f08d	6f23cb44-06f6-4c22-a3be-7a6fe4517572	logout	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:52.290268+07	\N	\N	\N	\N
afb965d7-e89d-46d9-8c57-23f475e9bdc1	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:56.101536+07	\N	\N	\N	\N
83272207-49bb-4b77-b987-ec4663064033	6f23cb44-06f6-4c22-a3be-7a6fe4517572	toggle_user_status	users	aad21b18-5924-4b9e-ba42-bccd18ff3713	Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:39:59.042383+07	\N	\N	\N	\N
9a51fd5b-9bdd-4046-b582-21b07315b2f4	6f23cb44-06f6-4c22-a3be-7a6fe4517572	reset_password	users	aad21b18-5924-4b9e-ba42-bccd18ff3713	Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:40:02.952437+07	\N	\N	\N	\N
aea9bb3f-3925-4207-9d57-49f6b17389fb	6f23cb44-06f6-4c22-a3be-7a6fe4517572	logout	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:40:07.894074+07	\N	\N	\N	\N
9dd85f3f-1ecc-48a5-9d4c-1237af106529	aad21b18-5924-4b9e-ba42-bccd18ff3713	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:40:16.585918+07	\N	\N	\N	\N
8f64275e-71c5-4d5e-9835-50f5570ef658	aad21b18-5924-4b9e-ba42-bccd18ff3713	logout	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:40:22.234221+07	\N	\N	\N	\N
ff07c91a-2b6c-4950-ace3-3891da458b20	6f23cb44-06f6-4c22-a3be-7a6fe4517572	login	auth	\N	\N	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:40:24.221787+07	\N	\N	\N	\N
50565224-490f-413f-b6ee-1c50d520c117	6f23cb44-06f6-4c22-a3be-7a6fe4517572	delete_user	users	aad21b18-5924-4b9e-ba42-bccd18ff3713	Farhan Ali	{}	::ffff:127.0.0.1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36	2026-07-10 00:40:31.955204+07	\N	\N	\N	\N
\.


--
-- Data for Name: backups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.backups (id, backup_code, document_id, status, file_size_bytes, notes, executed_by, executed_at, created_at) FROM stdin;
7644931b-36ed-406c-99b3-dc521ab77959	BKP-2026-0602-1632	\N	failed	\N	Gagal: new row for relation "documents" violates check constraint "documents_allowed_extension"	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-02 16:32:35.570573+07	2026-06-02 16:32:35.570573+07
66862295-fb8d-4348-a3ef-0376cacf5d98	BKP-2026-0602-1633	cff00240-8f97-4f1a-8c73-7bc94edd5ef5	success	70043	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-02 16:33:18.982052+07	2026-06-02 16:33:18.982052+07
5dadee72-7642-4dae-bb34-5886f828580d	BKP-2026-0604-1335	efc930ae-f90d-404c-9b54-63c5d5fcac89	success	71042	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-04 13:35:48.886751+07	2026-06-04 13:35:48.886751+07
f4eca5d6-546a-4671-a87f-7d52518d9d88	BKP-2026-0604-1349	fae61c77-f76a-4c42-a2f7-6cabe18c1856	success	71832	Manual backup triggered by Administrator	ea882088-79c4-4722-b64d-aebc68f8f79a	2026-06-04 13:49:08.911672+07	2026-06-04 13:49:08.911672+07
a295cb6f-588b-4468-ab13-a296bfcb21b5	BKP-2026-0617-1610	65f96c43-567f-4b5d-9c1d-21ba59654062	success	72335	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:10:46.761213+07	2026-06-17 16:10:46.761213+07
bf6bcb90-18e7-462b-b22e-45ad35706a95	BKP-2026-0617-1652	2907b624-d218-4ed1-8d49-834680192dc0	success	73950	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:52:09.58617+07	2026-06-17 16:52:09.58617+07
3779f08a-3b1f-4791-8e26-24f2ea7b99e9	BKP-2026-0617-1653	be9e539d-b941-434f-9099-8279fe73a4b1	success	74674	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:53:36.577863+07	2026-06-17 16:53:36.577863+07
e8f7402f-20ed-4eee-aa73-feec11ddc49d	BKP-2026-0617-1654	9db678b0-5e05-401f-9f25-63055d60f1d6	success	75361	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:54:34.317039+07	2026-06-17 16:54:34.317039+07
8ac4271c-42cd-4c65-8122-4c9e3585f88b	BKP-2026-0709-2354	f3700355-c06b-420d-8a8a-a6410ae40eb2	success	82977	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-09 23:54:54.516035+07	2026-07-09 23:54:54.516035+07
984d0615-595d-4b14-88b0-7af6454bdf03	BKP-2026-0710-0003	08e1d38d-03da-4e79-9509-a3b4da6dcf83	success	83742	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-10 00:03:41.07035+07	2026-07-10 00:03:41.07035+07
6b85a1e7-3b1d-479a-b45d-80e86f714a5e	BKP-2026-0710-0006	e56f0556-3b83-47da-89e2-4c4338c8c080	success	84756	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-10 00:06:23.909671+07	2026-07-10 00:06:23.909671+07
b502db56-2778-456a-bef2-e941d7496d0c	BKP-2026-0710-0016	b5b341f2-4d42-4e2e-b516-2b9ccfed98cf	success	85365	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-10 00:16:46.295636+07	2026-07-10 00:16:46.295636+07
99b98576-7cf0-4467-ad64-ff42afc43d1d	BKP-2026-0710-0025	af6e54c8-c7cb-4240-998a-370267d5ed75	success	85689	Manual backup triggered by Administrator	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-10 00:25:23.446061+07	2026-07-10 00:25:23.446061+07
\.


--
-- Data for Name: disposition_follow_ups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.disposition_follow_ups (id, disposition_id, notes, status, followed_up_by, followed_up_at, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: dispositions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dispositions (id, disposition_number, incoming_letter_id, giver_id, target_user_id, target_unit_id, instruction, due_date, priority, status, sent_at, received_at, followed_up_at, completed_at, created_at, updated_at, deleted_at) FROM stdin;
ad7cb957-064f-4705-b634-318a0cfa65ce	DSP-2026-021	f03edf65-02a0-40a2-9dc3-62be777e0350	f5015fb2-5672-41c2-bf9c-8bee47a21c79	76a563a6-e955-4544-b2cd-db0183fc3c6a	\N	Segera tindak lanjuti	2026-05-10	segera	dikirim	2026-06-17 17:00:31.404504+07	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
793594c6-e228-4f82-b9d8-f5c4dc2009b4	DSP-2026-020	0ea3e503-4b42-423b-ae8f-42a709dd4c43	f5015fb2-5672-41c2-bf9c-8bee47a21c79	76a563a6-e955-4544-b2cd-db0183fc3c6a	\N	Telaah dan laporkan	2026-05-11	biasa	ditindaklanjuti	2026-06-17 17:00:31.404504+07	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
ea15ea62-e1a4-432e-96b5-49ca2315159d	DSP-2026-019	10711dd3-cd70-419f-afaa-de86630f5f19	f5015fb2-5672-41c2-bf9c-8bee47a21c79	76a563a6-e955-4544-b2cd-db0183fc3c6a	\N	Arsipkan setelah selesai	2026-05-12	biasa	selesai	2026-06-17 17:00:31.404504+07	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
\.


--
-- Data for Name: documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.documents (id, owner_type, owner_id, original_name, stored_name, storage_path, mime_type, file_extension, file_size_bytes, checksum_sha256, previewable, uploaded_by, uploaded_at, deleted_at) FROM stdin;
cff00240-8f97-4f1a-8c73-7bc94edd5ef5	backup	66862295-fb8d-4348-a3ef-0376cacf5d98	BKP-2026-0602-1633.dump	e31ef35a-420c-4a43-9974-31c7deab161a.dump	storage/backups/BKP-2026-0602-1633.dump	application/octet-stream	dump	70043	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-02 16:33:18.982052+07	\N
efc930ae-f90d-404c-9b54-63c5d5fcac89	backup	5dadee72-7642-4dae-bb34-5886f828580d	BKP-2026-0604-1335.dump	755d7b28-51df-48f5-bd6f-fe9be77d2fcd.dump	storage/backups/BKP-2026-0604-1335.dump	application/octet-stream	dump	71042	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-04 13:35:48.886751+07	\N
fae61c77-f76a-4c42-a2f7-6cabe18c1856	backup	f4eca5d6-546a-4671-a87f-7d52518d9d88	BKP-2026-0604-1349.dump	588840ab-5536-484f-8f90-4f67f199f298.dump	storage/backups/BKP-2026-0604-1349.dump	application/octet-stream	dump	71832	\N	f	ea882088-79c4-4722-b64d-aebc68f8f79a	2026-06-04 13:49:08.911672+07	\N
65f96c43-567f-4b5d-9c1d-21ba59654062	backup	a295cb6f-588b-4468-ab13-a296bfcb21b5	BKP-2026-0617-1610.dump	fa8dab65-e4ce-492c-8305-a26cd6440985.dump	storage/backups/BKP-2026-0617-1610.dump	application/octet-stream	dump	72335	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:10:46.761213+07	\N
2907b624-d218-4ed1-8d49-834680192dc0	backup	bf6bcb90-18e7-462b-b22e-45ad35706a95	BKP-2026-0617-1652.dump	3c7cd6f9-00bb-4e39-bf8a-0ddc7680aaa5.dump	storage/backups/BKP-2026-0617-1652.dump	application/octet-stream	dump	73950	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:52:09.58617+07	\N
be9e539d-b941-434f-9099-8279fe73a4b1	backup	3779f08a-3b1f-4791-8e26-24f2ea7b99e9	BKP-2026-0617-1653.dump	336db600-ad76-4e53-a7b7-79b17ad8ee68.dump	storage/backups/BKP-2026-0617-1653.dump	application/octet-stream	dump	74674	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:53:36.577863+07	\N
9db678b0-5e05-401f-9f25-63055d60f1d6	backup	e8f7402f-20ed-4eee-aa73-feec11ddc49d	BKP-2026-0617-1654.dump	26744880-36fe-4cbb-bcde-2e64f3bf2055.dump	storage/backups/BKP-2026-0617-1654.dump	application/octet-stream	dump	75361	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-06-17 16:54:34.317039+07	\N
f3700355-c06b-420d-8a8a-a6410ae40eb2	backup	8ac4271c-42cd-4c65-8122-4c9e3585f88b	BKP-2026-0709-2354.dump	07c78560-7a39-4521-b70b-b5bff5a5fed2.dump	storage/backups/BKP-2026-0709-2354.dump	application/octet-stream	dump	82977	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-09 23:54:54.516035+07	\N
08e1d38d-03da-4e79-9509-a3b4da6dcf83	backup	984d0615-595d-4b14-88b0-7af6454bdf03	BKP-2026-0710-0003.dump	f36c86e2-b8fa-4e1c-810b-60bfbe728109.dump	storage/backups/BKP-2026-0710-0003.dump	application/octet-stream	dump	83742	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-10 00:03:41.07035+07	\N
e56f0556-3b83-47da-89e2-4c4338c8c080	backup	6b85a1e7-3b1d-479a-b45d-80e86f714a5e	BKP-2026-0710-0006.dump	d523da6c-e4aa-4004-b938-13254c61f14a.dump	storage/backups/BKP-2026-0710-0006.dump	application/octet-stream	dump	84756	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-10 00:06:23.909671+07	\N
b5b341f2-4d42-4e2e-b516-2b9ccfed98cf	backup	b502db56-2778-456a-bef2-e941d7496d0c	BKP-2026-0710-0016.dump	1fb68e33-35f8-457c-8ff2-2c05fd973b7d.dump	storage/backups/BKP-2026-0710-0016.dump	application/octet-stream	dump	85365	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-10 00:16:46.295636+07	\N
af6e54c8-c7cb-4240-998a-370267d5ed75	backup	99b98576-7cf0-4467-ad64-ff42afc43d1d	BKP-2026-0710-0025.dump	ef59d35c-7bc7-4d93-9395-7986886148b6.dump	storage/backups/BKP-2026-0710-0025.dump	application/octet-stream	dump	85689	\N	f	6f23cb44-06f6-4c22-a3be-7a6fe4517572	2026-07-10 00:25:23.446061+07	\N
\.


--
-- Data for Name: email_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_messages (id, direction, message_id, mailbox, sender, recipients, cc, subject, text_body, html_body, attachment_metadata, related_module, related_id, provider_metadata, received_at, sent_at, synced_by, created_at, process_status, processed_at, processed_by, processing_error) FROM stdin;
\.


--
-- Data for Name: incoming_letters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.incoming_letters (id, agenda_number, letter_number, letter_date, received_date, sender, subject, letter_type_id, letter_nature_id, summary, status, registered_by, forwarded_to, forwarded_by, forwarded_at, read_by_leader_at, completed_at, created_at, updated_at, deleted_at) FROM stdin;
f03edf65-02a0-40a2-9dc3-62be777e0350	AG-2026-041	SM/109/V/2026	2026-05-01	2026-05-02	Dinas Kominfo	Permintaan data layanan	180bb6ee-3c21-428a-9029-281d0ffb7d46	89dc6a8f-f95a-4820-bc28-42b7abc4b120	\N	diteruskan	c034e8e6-fad0-4994-832d-90e9c3459cf2	\N	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
07b65645-56e5-40b1-bc83-9afe73aabdbb	AG-2026-040	SM/108/V/2026	2026-05-01	2026-05-02	Bappeda	Koordinasi program	c78a6cc6-c553-49ff-a7fb-c1336c2487b2	3b83bdef-0c6d-4d3f-bd0b-6fd493b0deb3	\N	diregistrasi	c034e8e6-fad0-4994-832d-90e9c3459cf2	\N	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
0ea3e503-4b42-423b-ae8f-42a709dd4c43	AG-2026-039	SM/107/V/2026	2026-05-01	2026-05-02	Inspektorat	Jadwal audit	180bb6ee-3c21-428a-9029-281d0ffb7d46	a25f3cd6-ef8d-4f3b-837d-9f87890cc057	\N	didisposisikan	c034e8e6-fad0-4994-832d-90e9c3459cf2	\N	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
10711dd3-cd70-419f-afaa-de86630f5f19	AG-2026-038	SM/103/V/2026	2026-05-01	2026-05-02	Sekretariat Negara	Undangan Rapat	c5798aec-1afe-441f-a3d6-0c39af936914	89dc6a8f-f95a-4820-bc28-42b7abc4b120	\N	selesai	c034e8e6-fad0-4994-832d-90e9c3459cf2	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
\.


--
-- Data for Name: letter_natures; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.letter_natures (id, code, name, is_active, created_at, updated_at) FROM stdin;
89dc6a8f-f95a-4820-bc28-42b7abc4b120	biasa	Biasa	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
3b83bdef-0c6d-4d3f-bd0b-6fd493b0deb3	penting	Penting	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
a25f3cd6-ef8d-4f3b-837d-9f87890cc057	segera	Segera	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
739d85f5-6fcb-4f46-b0ce-9fa0821dc41e	rahasia	Rahasia	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
\.


--
-- Data for Name: letter_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.letter_requests (id, request_number, request_date, letter_type_id, subject, destination, body, applicant_id, applicant_unit_id, status, operator_id, approver_id, rejection_note, submitted_at, processed_at, approval_requested_at, approved_at, rejected_at, completed_at, created_by, updated_by, created_at, updated_at, deleted_at) FROM stdin;
7ad18818-8ee0-471b-9b52-a1d0f8ba7cb5	AJ-2026-0007	2026-05-01	c78a6cc6-c553-49ff-a7fb-c1336c2487b2	Pendampingan audit internal	Unit Internal	Detail permohonan audit...	76a563a6-e955-4544-b2cd-db0183fc3c6a	\N	menunggu_approval	\N	\N	\N	2026-06-17 17:00:31.404504+07	\N	\N	\N	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
0dd469e0-acf2-4c2c-807a-ee9b6b89dbc1	AJ-2026-0006	2026-05-02	9127a564-9d4c-47a4-b4f4-c2103cf13826	Keterangan aktif pegawai	Kepegawaian	Detail keterangan...	76a563a6-e955-4544-b2cd-db0183fc3c6a	\N	diproses_operator	\N	\N	\N	2026-06-17 17:00:31.404504+07	\N	\N	\N	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
7ce0e8b7-aebd-4d1d-9781-ce66facd39c6	AJ-2026-0005	2026-05-03	c5798aec-1afe-441f-a3d6-0c39af936914	Undangan rapat koordinasi	Mitra Kerja	Detail undangan...	76a563a6-e955-4544-b2cd-db0183fc3c6a	\N	disetujui	\N	\N	\N	2026-06-17 17:00:31.404504+07	\N	\N	2026-06-17 17:00:31.404504+07	\N	2026-06-17 17:00:31.404504+07	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
\.


--
-- Data for Name: letter_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.letter_types (id, name, description, is_active, created_at, updated_at) FROM stdin;
c5798aec-1afe-441f-a3d6-0c39af936914	Surat Undangan	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
7375ebd6-41ad-4e7c-909f-416710999766	Surat Pengumuman	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
180bb6ee-3c21-428a-9029-281d0ffb7d46	Surat Permohonan	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
2e7ec602-d847-408b-8d27-6b0450ddc541	Surat Keputusan	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
c78a6cc6-c553-49ff-a7fb-c1336c2487b2	Surat Tugas	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
63cb4b13-269c-409e-a0ec-e065deea84c1	Surat Edaran	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
9127a564-9d4c-47a4-b4f4-c2103cf13826	Surat Keterangan	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
d1e2934b-5995-41b9-a67d-ab233299bddc	Surat Izin Penelitian	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
1b82b9b6-2ebe-4d79-b58a-6d63317716f0	Surat Lainnya	\N	t	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, recipient_id, type, title, message, source_type, source_id, is_read, read_at, created_at) FROM stdin;
\.


--
-- Data for Name: outgoing_letters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.outgoing_letters (id, letter_number, letter_date, letter_type_id, destination, subject, summary, status, created_by, checked_by, approver_id, rejection_note, sent_method, sent_reference, checked_at, approval_requested_at, approved_at, rejected_at, sent_at, created_at, updated_at, deleted_at) FROM stdin;
4edecba6-1e0d-462a-8e9a-0612104eaec6	SK-2026-018	2026-05-01	63cb4b13-269c-409e-a0ec-e065deea84c1	Unit Internal	Pembaruan SOP arsip	\N	menunggu_approval	c034e8e6-fad0-4994-832d-90e9c3459cf2	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
e69f3a07-805d-4b1d-8c28-e4dfc079be0f	SK-2026-017	2026-05-02	c5798aec-1afe-441f-a3d6-0c39af936914	Mitra Kerja	Rapat evaluasi triwulan	\N	disetujui	c034e8e6-fad0-4994-832d-90e9c3459cf2	\N	\N	\N	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	\N	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
cceb6146-81bb-42b5-951c-be7130291b6d	SK-2026-016	2026-05-03	c78a6cc6-c553-49ff-a7fb-c1336c2487b2	Pegawai	Kegiatan lapangan	\N	dikirim	c034e8e6-fad0-4994-832d-90e9c3459cf2	\N	\N	\N	\N	\N	\N	\N	2026-06-17 17:00:31.404504+07	\N	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	2026-06-17 17:00:31.404504+07	\N
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permissions (id, code, name, module, created_at) FROM stdin;
052a8436-87ba-4141-ba11-7ab03a5a5bdc	dashboard.read	Lihat dashboard	dashboard	2026-06-02 15:53:44.826739+07
54ae67d8-60de-4e98-a224-b7dbe9a90828	users.manage	Kelola pengguna	users	2026-06-02 15:53:44.826739+07
fc886f2e-d8d6-41c0-945d-0dd11c89419c	roles.manage	Kelola role dan permission	roles	2026-06-02 15:53:44.826739+07
68c840c1-1bc3-4103-bfe6-90a59212dd40	letter_requests.create	Buat ajuan surat	letter_requests	2026-06-02 15:53:44.826739+07
f94fb3fb-4ded-4146-891b-2f842db514d5	letter_requests.read	Lihat ajuan surat	letter_requests	2026-06-02 15:53:44.826739+07
24c38700-3222-4212-9af0-62dc3136f4f1	letter_requests.process	Proses ajuan surat	letter_requests	2026-06-02 15:53:44.826739+07
e0e43052-2da8-483a-a5ec-fc37882c3b6f	letter_requests.approve	Approve/reject ajuan surat	letter_requests	2026-06-02 15:53:44.826739+07
a19ce704-3520-4b64-b182-41e1b5842c44	incoming_letters.create	Registrasi surat masuk	incoming_letters	2026-06-02 15:53:44.826739+07
b390df9a-2d82-4e5b-b119-f6bdf9e768b0	incoming_letters.read	Lihat surat masuk	incoming_letters	2026-06-02 15:53:44.826739+07
a913e556-1d7e-49b4-93e3-932b9cddd1c5	incoming_letters.forward	Teruskan surat masuk	incoming_letters	2026-06-02 15:53:44.826739+07
5c78ad03-6079-461f-9bdb-b46eae4aff95	outgoing_letters.create	Buat surat keluar	outgoing_letters	2026-06-02 15:53:44.826739+07
abcdfe59-8144-413e-ac9e-e578b36d0667	outgoing_letters.read	Lihat surat keluar	outgoing_letters	2026-06-02 15:53:44.826739+07
df9c1988-26df-4e22-a1cc-166b4c99cedc	outgoing_letters.process	Proses surat keluar	outgoing_letters	2026-06-02 15:53:44.826739+07
7fff2d42-b4b6-49da-99c6-7b15d415beee	outgoing_letters.approve	Approve/reject surat keluar	outgoing_letters	2026-06-02 15:53:44.826739+07
d19fbdc1-5a26-4f11-b668-47ae16378f7a	dispositions.create	Buat disposisi	dispositions	2026-06-02 15:53:44.826739+07
03c37ad0-7f90-4f60-a75d-49e5243cf159	dispositions.read	Lihat disposisi	dispositions	2026-06-02 15:53:44.826739+07
d529cca8-09e0-431d-b69f-33a3392ba118	dispositions.follow_up	Tindak lanjut disposisi	dispositions	2026-06-02 15:53:44.826739+07
19fe93f0-1a4b-46c1-8bc4-9683fb56af09	archives.read	Lihat arsip digital	archives	2026-06-02 15:53:44.826739+07
2adfab92-fbaa-4e46-99ec-959023de3080	archives.download	Download dokumen arsip	archives	2026-06-02 15:53:44.826739+07
1beb8c0f-e499-4f92-9182-af4846e8b852	notifications.read	Lihat notifikasi	notifications	2026-06-02 15:53:44.826739+07
ccf3a5a1-9454-4efe-b9b1-aca6e215f824	reports.read	Lihat laporan	reports	2026-06-02 15:53:44.826739+07
3d7d2afb-b9a7-43de-aaa5-78c5678db49e	reports.export	Export laporan	reports	2026-06-02 15:53:44.826739+07
af1445e6-5548-4ef1-a7c0-6742d2acd696	audit_logs.read	Lihat audit trail	audit_logs	2026-06-02 15:53:44.826739+07
ab53ff4b-437e-4a99-a6eb-bb908642e8b7	backups.manage	Kelola backup database	backups	2026-06-02 15:53:44.826739+07
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_permissions (role_id, permission_id, created_at) FROM stdin;
88be5061-16cc-4f66-8ab2-88454d896b54	052a8436-87ba-4141-ba11-7ab03a5a5bdc	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	052a8436-87ba-4141-ba11-7ab03a5a5bdc	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	052a8436-87ba-4141-ba11-7ab03a5a5bdc	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	052a8436-87ba-4141-ba11-7ab03a5a5bdc	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	54ae67d8-60de-4e98-a224-b7dbe9a90828	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	fc886f2e-d8d6-41c0-945d-0dd11c89419c	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	68c840c1-1bc3-4103-bfe6-90a59212dd40	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	68c840c1-1bc3-4103-bfe6-90a59212dd40	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	f94fb3fb-4ded-4146-891b-2f842db514d5	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	f94fb3fb-4ded-4146-891b-2f842db514d5	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	f94fb3fb-4ded-4146-891b-2f842db514d5	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	f94fb3fb-4ded-4146-891b-2f842db514d5	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	24c38700-3222-4212-9af0-62dc3136f4f1	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	24c38700-3222-4212-9af0-62dc3136f4f1	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	e0e43052-2da8-483a-a5ec-fc37882c3b6f	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	e0e43052-2da8-483a-a5ec-fc37882c3b6f	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	a19ce704-3520-4b64-b182-41e1b5842c44	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	a19ce704-3520-4b64-b182-41e1b5842c44	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	b390df9a-2d82-4e5b-b119-f6bdf9e768b0	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	b390df9a-2d82-4e5b-b119-f6bdf9e768b0	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	b390df9a-2d82-4e5b-b119-f6bdf9e768b0	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	a913e556-1d7e-49b4-93e3-932b9cddd1c5	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	a913e556-1d7e-49b4-93e3-932b9cddd1c5	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	5c78ad03-6079-461f-9bdb-b46eae4aff95	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	5c78ad03-6079-461f-9bdb-b46eae4aff95	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	abcdfe59-8144-413e-ac9e-e578b36d0667	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	abcdfe59-8144-413e-ac9e-e578b36d0667	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	abcdfe59-8144-413e-ac9e-e578b36d0667	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	df9c1988-26df-4e22-a1cc-166b4c99cedc	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	df9c1988-26df-4e22-a1cc-166b4c99cedc	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	7fff2d42-b4b6-49da-99c6-7b15d415beee	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	7fff2d42-b4b6-49da-99c6-7b15d415beee	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	d19fbdc1-5a26-4f11-b668-47ae16378f7a	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	d19fbdc1-5a26-4f11-b668-47ae16378f7a	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	03c37ad0-7f90-4f60-a75d-49e5243cf159	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	03c37ad0-7f90-4f60-a75d-49e5243cf159	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	03c37ad0-7f90-4f60-a75d-49e5243cf159	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	d529cca8-09e0-431d-b69f-33a3392ba118	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	d529cca8-09e0-431d-b69f-33a3392ba118	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	19fe93f0-1a4b-46c1-8bc4-9683fb56af09	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	19fe93f0-1a4b-46c1-8bc4-9683fb56af09	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	19fe93f0-1a4b-46c1-8bc4-9683fb56af09	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	19fe93f0-1a4b-46c1-8bc4-9683fb56af09	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	2adfab92-fbaa-4e46-99ec-959023de3080	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	2adfab92-fbaa-4e46-99ec-959023de3080	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	2adfab92-fbaa-4e46-99ec-959023de3080	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	2adfab92-fbaa-4e46-99ec-959023de3080	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	1beb8c0f-e499-4f92-9182-af4846e8b852	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	1beb8c0f-e499-4f92-9182-af4846e8b852	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	1beb8c0f-e499-4f92-9182-af4846e8b852	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	1beb8c0f-e499-4f92-9182-af4846e8b852	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	ccf3a5a1-9454-4efe-b9b1-aca6e215f824	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	ccf3a5a1-9454-4efe-b9b1-aca6e215f824	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	ccf3a5a1-9454-4efe-b9b1-aca6e215f824	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	3d7d2afb-b9a7-43de-aaa5-78c5678db49e	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	3d7d2afb-b9a7-43de-aaa5-78c5678db49e	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	3d7d2afb-b9a7-43de-aaa5-78c5678db49e	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	af1445e6-5548-4ef1-a7c0-6742d2acd696	2026-06-02 15:53:44.826739+07
88be5061-16cc-4f66-8ab2-88454d896b54	ab53ff4b-437e-4a99-a6eb-bb908642e8b7	2026-06-02 15:53:44.826739+07
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, code, name, description, created_at, updated_at) FROM stdin;
88be5061-16cc-4f66-8ab2-88454d896b54	administrator	Administrator	Mengelola pengguna, role, konfigurasi, audit trail, backup, dan master data.	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
3b51b9b4-4152-4d0a-8483-d34232ce88f7	operator	Operator	Meregistrasi surat masuk, memproses ajuan, mengelola surat keluar, dan laporan operasional.	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
390db138-b16e-4d75-bc80-25b1a56c3bb9	pimpinan	Pimpinan	Membaca surat, membuat disposisi, approval/reject ajuan dan surat keluar.	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
bf685220-5a5f-44be-a6ec-6d9c8a621e03	user	User	Mengajukan surat, melihat status, menerima disposisi, dan mengirim tindak lanjut.	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (id, filename, checksum_sha256, executed_at) FROM stdin;
1	001_schema.sql	745b9ec13324dbad463b3e41dbe4c9c360a217ca607a2c25a2083dbb43fae10a	2026-06-02 15:53:44.826739+07
2	002_seed.sql	37e5a95ccd042c8cee9237f43db91c8438b80cd74a3f3595517737749748b03a	2026-06-02 15:53:44.826739+07
3	003_audit_reviews.sql	f851a6e4a5b600a5125a24d053ad907b68acf77b09c6c392ae43036e5e9bdb93	2026-06-02 16:00:34.11503+07
4	004_allow_backup_extensions.sql	4f4162c34782b15e71818a231e3e447ebaa8d09add5ed7a3e9a7b6879300af5e	2026-06-02 16:33:00.189047+07
5	005_seed_letters.sql	70e5e2539c19c7d6dabd6582b7dcc8c3a9d9d768f780f5e10bd0961276c3df27	2026-06-17 17:00:31.404504+07
6	003_email_integration.sql	6ac9bd93383418d7d1803c2edb7d93dc6acc5f626baec4d60da2ff50e2f822bf	2026-07-09 23:37:10.251549+07
7	004_email_inbox_processing.sql	411294217a374a85fc6aa373ec3e7fb8d407d105e2c362003eb4ed6ba8105215	2026-07-09 23:37:10.251549+07
\.


--
-- Data for Name: units; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.units (id, name, description, created_at, updated_at, deleted_at) FROM stdin;
d6e2821d-5b56-4584-9f00-021c0aefb33e	Pimpinan	Unit pimpinan atau kepala bagian.	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07	\N
c8560a45-0f65-47a9-8950-5f5dd2de4a5a	Kepegawaian	Unit pengguna demo untuk ajuan surat.	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07	\N
f40846d7-c089-4d58-8153-85b3c640e2e1	Akademik	Unit pemohon dan arsip akademik.	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07	\N
0dfe9ab1-a8fc-4bc3-a968-36ef973e64c6	Keuangan	Unit penerima disposisi dan dokumen.	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07	\N
79acdc88-bde6-4938-8c61-990fa79ab425	Sistem Informasi IT	\N	2026-06-17 16:34:55.083334+07	2026-06-17 16:34:55.083334+07	\N
a67f3d76-a12a-4745-b4c8-b3401addcde5	Kehumasan	\N	2026-06-17 16:38:39.500526+07	2026-06-17 16:38:39.500526+07	\N
2d25ec99-1d13-4f1f-ae43-67dbb26c81a5	Tata Usaha	Unit operator persuratan.	2026-06-02 15:53:44.826739+07	2026-07-10 00:06:23.762755+07	\N
56917bcb-fd06-44d0-aaa7-5cc447227a38	Humas	\N	2026-06-17 16:52:09.441257+07	2026-07-10 00:06:23.793259+07	\N
010dc551-5db1-4f90-9529-314d8e13c639	Sistem Informasi	Unit pengelola sistem dan administrator.	2026-06-02 15:53:44.826739+07	2026-07-10 00:06:23.804836+07	\N
557987c6-b3e7-4d26-a26c-d4953916f904	Bagian Keuangan	\N	2026-07-10 00:35:08.445869+07	2026-07-10 00:35:08.445869+07	\N
837c3c6f-172c-47a9-8501-d58f34048e88	BAAK	\N	2026-06-04 13:38:31.822958+07	2026-07-10 00:39:43.339245+07	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, role_id, unit_id, full_name, username, email, password_hash, "position", phone, address, status, must_change_password, last_login_at, created_by, updated_by, created_at, updated_at, deleted_at) FROM stdin;
c034e8e6-fad0-4994-832d-90e9c3459cf2	3b51b9b4-4152-4d0a-8483-d34232ce88f7	2d25ec99-1d13-4f1f-ae43-67dbb26c81a5	Rina Operator	operator	operator@e-office.local	$2a$06$/e/bBq186.Nigqaj5atKfe58UpzjnWckTgjd.VypPaWlol3GYeyEi	Operator Persuratan	\N	\N	aktif	t	\N	\N	\N	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07	\N
f5015fb2-5672-41c2-bf9c-8bee47a21c79	390db138-b16e-4d75-bc80-25b1a56c3bb9	d6e2821d-5b56-4584-9f00-021c0aefb33e	Dewi Pimpinan	pimpinan	pimpinan@e-office.local	$2a$06$U3FeW/pKKqt5DfCe24Tp8eNpIlbKLbqllDSlhGvF2M8n5kZr0PWGS	Kepala Bagian	\N	\N	aktif	t	\N	\N	\N	2026-06-02 15:53:44.826739+07	2026-06-02 15:53:44.826739+07	\N
6f23cb44-06f6-4c22-a3be-7a6fe4517572	88be5061-16cc-4f66-8ab2-88454d896b54	010dc551-5db1-4f90-9529-314d8e13c639	Administrator System	admin	admin@stt-pu.ac.id	$2a$06$grK8WOrT7E2OJwBPAqEYceU2knHUGb7nSMErprynVTnWjtgD9Vql.	Head of IT	\N	\N	aktif	t	2026-07-10 00:40:24.220902+07	\N	\N	2026-06-02 15:53:44.826739+07	2026-07-10 00:40:24.220902+07	\N
76a563a6-e955-4544-b2cd-db0183fc3c6a	bf685220-5a5f-44be-a6ec-6d9c8a621e03	c8560a45-0f65-47a9-8950-5f5dd2de4a5a	Budi Santoso	user	user@e-office.local	$2a$06$IjUm.r9heDiD1VrhCqHEoe2PKRSpPoPQssOwozFcj39lzl532iJSO	Staf Kepegawaian	\N	\N	aktif	t	2026-06-04 14:13:17.744115+07	\N	\N	2026-06-02 15:53:44.826739+07	2026-06-04 14:13:17.744115+07	\N
4c24312e-275a-4f30-b10a-3fc248b4597c	bf685220-5a5f-44be-a6ec-6d9c8a621e03	\N	Test User	testuser2	\N	$2a$06$.iy82a697.ySjpWDew497eVVT1BFI7J1bT3z.yyhf2YLHyBcJaQyO	\N	\N	\N	nonaktif	t	\N	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-07-10 00:12:22.416285+07	2026-07-10 00:32:21.502871+07	2026-07-10 00:32:21.502871+07
84affe69-87f4-44f9-830b-a82e33ca5cd5	bf685220-5a5f-44be-a6ec-6d9c8a621e03	2d25ec99-1d13-4f1f-ae43-67dbb26c81a5	Test Auditor	testauditor_016365	auditor_016365@stt-pu.ac.id	$2a$06$VaPPxlezfjvYhEab9QPbHOFD4F8N.mkEKf2B1cLGKXvIsuOAWD8AK	\N	\N	\N	nonaktif	t	2026-06-17 16:53:36.398723+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-06-17 16:53:36.36943+07	2026-07-10 00:32:36.365809+07	2026-07-10 00:32:36.365809+07
03cc6aa9-a5aa-4d08-ac89-bf04460d9f37	bf685220-5a5f-44be-a6ec-6d9c8a621e03	2d25ec99-1d13-4f1f-ae43-67dbb26c81a5	Asep Test	aseptest_1780554948717	asep_1780554948717@e-office.local	$2a$06$iXnTtJJF8oXgWUHXiPzbsukUJ1U.ZdyJUoP.fz0Rp.rXbi4m22ot6	Staf Admin	\N	\N	nonaktif	t	\N	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-06-04 13:35:48.720977+07	2026-07-10 00:32:44.940043+07	2026-07-10 00:32:44.940043+07
e40af09e-843a-4aa4-9f6d-f7d68d486bf7	bf685220-5a5f-44be-a6ec-6d9c8a621e03	2d25ec99-1d13-4f1f-ae43-67dbb26c81a5	Asep Test	aseptest_1780392804591	asep_1780392804591@e-office.local	$2a$06$obQqLdztjdVxLLGN5.vamuxr.D8KFezRWRXT6cYqSI1Nf04KW0rhC	Staf Admin	\N	\N	nonaktif	t	\N	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-06-02 16:33:24.594408+07	2026-07-10 00:32:46.725788+07	2026-07-10 00:32:46.725788+07
72ef88d7-60ef-458a-8af6-5f862c1796ec	390db138-b16e-4d75-bc80-25b1a56c3bb9	557987c6-b3e7-4d26-a26c-d4953916f904	123	dsada	sansan.internal@gmail.com	$2a$06$ytTJJwUk/5U43lnrNkd5nOjZL05t4RmSw.qfptqXHbcN.XLY1c5/a	Ketua STTPU	\N	\N	nonaktif	t	\N	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-07-10 00:35:08.445869+07	2026-07-10 00:35:53.882337+07	2026-07-10 00:35:53.882337+07
ad9ae71b-9f71-470e-a45f-9a7e6955b91d	3b51b9b4-4152-4d0a-8483-d34232ce88f7	56917bcb-fd06-44d0-aaa7-5cc447227a38	Test Auditor Updated	testauditor_783760	auditor_783760.updated@stt-pu.ac.id	$2a$06$/oYo479xBF4Voyl1zghXJucH/p.BPn/gMBG9kKJebzfb7zenZwJPe	\N	\N	\N	nonaktif	t	2026-07-10 00:06:23.787282+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-07-10 00:06:23.762755+07	2026-07-10 00:32:26.650633+07	2026-07-10 00:32:26.650633+07
75bde822-d996-4d1a-8133-86bec399d61b	3b51b9b4-4152-4d0a-8483-d34232ce88f7	56917bcb-fd06-44d0-aaa7-5cc447227a38	Test Auditor Updated	testauditor_738369	auditor_738369.updated@stt-pu.ac.id	$2a$06$7ktIwHdYAsNOD31a9/fUje8uoSl3nt/AlmZv7UE87IhyDBow5PKDa	\N	\N	\N	nonaktif	t	2026-07-10 00:05:38.391141+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-07-10 00:05:38.371391+07	2026-07-10 00:32:28.495954+07	2026-07-10 00:32:28.495954+07
25f7a7e0-0ac9-412e-985a-0d400f78360d	3b51b9b4-4152-4d0a-8483-d34232ce88f7	56917bcb-fd06-44d0-aaa7-5cc447227a38	Test Auditor Updated	testauditor_620888	auditor_620888.updated@stt-pu.ac.id	$2a$06$tChHyA1cFT15vAERzQvbm.iOFqeG2vVVca3adkb7ANtujbGXhoWOO	\N	\N	\N	nonaktif	t	2026-07-10 00:03:40.91542+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-07-10 00:03:40.890767+07	2026-07-10 00:32:30.458018+07	2026-07-10 00:32:30.458018+07
99ec6477-da63-4145-93ec-9f89c1053c2f	3b51b9b4-4152-4d0a-8483-d34232ce88f7	56917bcb-fd06-44d0-aaa7-5cc447227a38	Test Auditor Updated	testauditor_094318	auditor_094318.updated@stt-pu.ac.id	$2a$06$z4vZteaSjKmzPu8Fh4Bor.U3slSHexoAUCcZUz4/2RKnfKnUrxrWm	\N	\N	\N	nonaktif	t	2026-07-09 23:54:54.346091+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-07-09 23:54:54.32113+07	2026-07-10 00:32:32.209163+07	2026-07-10 00:32:32.209163+07
4e143772-e8c8-4fa1-bf8b-e84252874aae	3b51b9b4-4152-4d0a-8483-d34232ce88f7	56917bcb-fd06-44d0-aaa7-5cc447227a38	Test Auditor Updated	testauditor_074161	auditor_074161.updated@stt-pu.ac.id	$2a$06$3CHcVbcfRo1wHwpXCwkR4.lMSe//PvZwupElae8rYhRo2zHvLbw6G	\N	\N	\N	nonaktif	t	2026-06-17 16:54:34.188476+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-06-17 16:54:34.164441+07	2026-07-10 00:32:34.211873+07	2026-07-10 00:32:34.211873+07
2fcdac58-d028-4dc1-bfda-42a8ed0e767c	3b51b9b4-4152-4d0a-8483-d34232ce88f7	56917bcb-fd06-44d0-aaa7-5cc447227a38	Test Auditor Updated	testauditor	auditor.updated@stt-pu.ac.id	$2a$06$lGoOsOAiDS7GH6xgoHQ3keX5t0ZCJkmZ4PesSbrn2ObwXXYQRhhSG	\N	\N	\N	nonaktif	t	2026-06-17 16:52:09.433829+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-06-17 16:52:09.40541+07	2026-07-10 00:32:38.339084+07	2026-07-10 00:32:38.339084+07
c0040bda-b8bc-4fff-a2e9-78fde204afc7	bf685220-5a5f-44be-a6ec-6d9c8a621e03	2d25ec99-1d13-4f1f-ae43-67dbb26c81a5	Asep Test	aseptest_1780392755400	asep@e-office.local	$2a$06$J032v8Y0/Bbc5ijQEaARBegjJ.QHWh5yqeDg3G.69rI.EFTf04eaW	Staf Admin	\N	\N	nonaktif	t	\N	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-06-02 16:32:35.405265+07	2026-07-10 00:32:48.552804+07	2026-07-10 00:32:48.552804+07
aad21b18-5924-4b9e-ba42-bccd18ff3713	bf685220-5a5f-44be-a6ec-6d9c8a621e03	837c3c6f-172c-47a9-8501-d58f34048e88	Farhan Ali	farhan	mochamadfarhanali@gmail.com	$2a$06$7gazlnsHgN.GXdK6SzQt/ePgdhLFCziCIo/nxFwHvq4fA1PI.hNsK	Staf	\N	\N	nonaktif	t	2026-07-10 00:40:16.584719+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-07-10 00:39:15.951574+07	2026-07-10 00:40:31.945272+07	2026-07-10 00:40:31.945272+07
ea882088-79c4-4722-b64d-aebc68f8f79a	88be5061-16cc-4f66-8ab2-88454d896b54	837c3c6f-172c-47a9-8501-d58f34048e88	Mochamad Farhan Ali	farhan	mochamadfarhanali@gmail.com	$2a$06$Dd5sSA7jvIkGoc92OhD/tOOO2LbKl88enAKrAmGNMWEjUxFSs13vS	Staf	\N	\N	nonaktif	t	2026-06-04 13:48:32.532742+07	6f23cb44-06f6-4c22-a3be-7a6fe4517572	\N	2026-06-04 13:38:31.822958+07	2026-07-10 00:33:37.070926+07	2026-07-10 00:33:37.070926+07
\.


--
-- Name: schema_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schema_migrations_id_seq', 7, true);


--
-- Name: archives archives_archive_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archives
    ADD CONSTRAINT archives_archive_number_key UNIQUE (archive_number);


--
-- Name: archives archives_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archives
    ADD CONSTRAINT archives_pkey PRIMARY KEY (id);


--
-- Name: archives archives_source_type_source_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archives
    ADD CONSTRAINT archives_source_type_source_id_key UNIQUE (source_type, source_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: backups backups_backup_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT backups_backup_code_key UNIQUE (backup_code);


--
-- Name: backups backups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT backups_pkey PRIMARY KEY (id);


--
-- Name: disposition_follow_ups disposition_follow_ups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.disposition_follow_ups
    ADD CONSTRAINT disposition_follow_ups_pkey PRIMARY KEY (id);


--
-- Name: dispositions dispositions_disposition_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispositions
    ADD CONSTRAINT dispositions_disposition_number_key UNIQUE (disposition_number);


--
-- Name: dispositions dispositions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispositions
    ADD CONSTRAINT dispositions_pkey PRIMARY KEY (id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: documents documents_stored_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_stored_name_key UNIQUE (stored_name);


--
-- Name: email_messages email_messages_direction_message_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT email_messages_direction_message_id_key UNIQUE (direction, message_id);


--
-- Name: email_messages email_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT email_messages_pkey PRIMARY KEY (id);


--
-- Name: incoming_letters incoming_letters_agenda_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incoming_letters
    ADD CONSTRAINT incoming_letters_agenda_number_key UNIQUE (agenda_number);


--
-- Name: incoming_letters incoming_letters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incoming_letters
    ADD CONSTRAINT incoming_letters_pkey PRIMARY KEY (id);


--
-- Name: letter_natures letter_natures_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_natures
    ADD CONSTRAINT letter_natures_code_key UNIQUE (code);


--
-- Name: letter_natures letter_natures_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_natures
    ADD CONSTRAINT letter_natures_pkey PRIMARY KEY (id);


--
-- Name: letter_requests letter_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_pkey PRIMARY KEY (id);


--
-- Name: letter_requests letter_requests_request_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_request_number_key UNIQUE (request_number);


--
-- Name: letter_types letter_types_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_types
    ADD CONSTRAINT letter_types_name_key UNIQUE (name);


--
-- Name: letter_types letter_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_types
    ADD CONSTRAINT letter_types_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: outgoing_letters outgoing_letters_letter_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_letters
    ADD CONSTRAINT outgoing_letters_letter_number_key UNIQUE (letter_number);


--
-- Name: outgoing_letters outgoing_letters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_letters
    ADD CONSTRAINT outgoing_letters_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_code_key UNIQUE (code);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: roles roles_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_code_key UNIQUE (code);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_filename_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_filename_key UNIQUE (filename);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (id);


--
-- Name: units units_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_name_key UNIQUE (name);


--
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_archives_source; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_archives_source ON public.archives USING btree (source_type, source_id);


--
-- Name: idx_archives_subject_trgm_fallback; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_archives_subject_trgm_fallback ON public.archives USING btree (lower((subject)::text));


--
-- Name: idx_audit_logs_filter; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_filter ON public.audit_logs USING btree (module, user_id, created_at DESC);


--
-- Name: idx_audit_logs_review_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_review_status ON public.audit_logs USING btree (review_status) WHERE (review_status IS NOT NULL);


--
-- Name: idx_dispositions_incoming_letter; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dispositions_incoming_letter ON public.dispositions USING btree (incoming_letter_id);


--
-- Name: idx_dispositions_target_user_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dispositions_target_user_status ON public.dispositions USING btree (target_user_id, status) WHERE (deleted_at IS NULL);


--
-- Name: idx_documents_owner; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_documents_owner ON public.documents USING btree (owner_type, owner_id);


--
-- Name: idx_email_messages_direction_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_email_messages_direction_created ON public.email_messages USING btree (direction, created_at DESC);


--
-- Name: idx_email_messages_incoming_process; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_email_messages_incoming_process ON public.email_messages USING btree (direction, process_status, received_at DESC);


--
-- Name: idx_email_messages_incoming_related_once; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_email_messages_incoming_related_once ON public.email_messages USING btree (related_id) WHERE (((direction)::text = 'incoming'::text) AND (related_id IS NOT NULL));


--
-- Name: idx_email_messages_related; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_email_messages_related ON public.email_messages USING btree (related_module, related_id);


--
-- Name: idx_incoming_letters_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_incoming_letters_dates ON public.incoming_letters USING btree (letter_date, received_date);


--
-- Name: idx_incoming_letters_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_incoming_letters_status ON public.incoming_letters USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: idx_letter_requests_applicant_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_letter_requests_applicant_status ON public.letter_requests USING btree (applicant_id, status) WHERE (deleted_at IS NULL);


--
-- Name: idx_letter_requests_request_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_letter_requests_request_date ON public.letter_requests USING btree (request_date);


--
-- Name: idx_notifications_recipient_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_recipient_read ON public.notifications USING btree (recipient_id, is_read, created_at DESC);


--
-- Name: idx_outgoing_letters_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_outgoing_letters_date ON public.outgoing_letters USING btree (letter_date);


--
-- Name: idx_outgoing_letters_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_outgoing_letters_status ON public.outgoing_letters USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: idx_users_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role_id ON public.users USING btree (role_id);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_status ON public.users USING btree (status) WHERE (deleted_at IS NULL);


--
-- Name: idx_users_unit_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_unit_id ON public.users USING btree (unit_id);


--
-- Name: users_email_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email) WHERE (deleted_at IS NULL);


--
-- Name: users_username_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX users_username_key ON public.users USING btree (username) WHERE (deleted_at IS NULL);


--
-- Name: archives trg_archives_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_archives_updated_at BEFORE UPDATE ON public.archives FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: disposition_follow_ups trg_disposition_follow_ups_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_disposition_follow_ups_updated_at BEFORE UPDATE ON public.disposition_follow_ups FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: dispositions trg_dispositions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_dispositions_updated_at BEFORE UPDATE ON public.dispositions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: incoming_letters trg_incoming_letters_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_incoming_letters_updated_at BEFORE UPDATE ON public.incoming_letters FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: letter_natures trg_letter_natures_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_letter_natures_updated_at BEFORE UPDATE ON public.letter_natures FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: letter_requests trg_letter_requests_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_letter_requests_updated_at BEFORE UPDATE ON public.letter_requests FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: letter_types trg_letter_types_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_letter_types_updated_at BEFORE UPDATE ON public.letter_types FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: outgoing_letters trg_outgoing_letters_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_outgoing_letters_updated_at BEFORE UPDATE ON public.outgoing_letters FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: roles trg_roles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: units trg_units_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_units_updated_at BEFORE UPDATE ON public.units FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: archives archives_archived_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archives
    ADD CONSTRAINT archives_archived_by_fkey FOREIGN KEY (archived_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: archives archives_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archives
    ADD CONSTRAINT archives_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE SET NULL;


--
-- Name: archives archives_letter_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.archives
    ADD CONSTRAINT archives_letter_type_id_fkey FOREIGN KEY (letter_type_id) REFERENCES public.letter_types(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: backups backups_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT backups_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE SET NULL;


--
-- Name: backups backups_executed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT backups_executed_by_fkey FOREIGN KEY (executed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: disposition_follow_ups disposition_follow_ups_disposition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.disposition_follow_ups
    ADD CONSTRAINT disposition_follow_ups_disposition_id_fkey FOREIGN KEY (disposition_id) REFERENCES public.dispositions(id) ON DELETE CASCADE;


--
-- Name: disposition_follow_ups disposition_follow_ups_followed_up_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.disposition_follow_ups
    ADD CONSTRAINT disposition_follow_ups_followed_up_by_fkey FOREIGN KEY (followed_up_by) REFERENCES public.users(id);


--
-- Name: dispositions dispositions_giver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispositions
    ADD CONSTRAINT dispositions_giver_id_fkey FOREIGN KEY (giver_id) REFERENCES public.users(id);


--
-- Name: dispositions dispositions_incoming_letter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispositions
    ADD CONSTRAINT dispositions_incoming_letter_id_fkey FOREIGN KEY (incoming_letter_id) REFERENCES public.incoming_letters(id);


--
-- Name: dispositions dispositions_target_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispositions
    ADD CONSTRAINT dispositions_target_unit_id_fkey FOREIGN KEY (target_unit_id) REFERENCES public.units(id) ON DELETE SET NULL;


--
-- Name: dispositions dispositions_target_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dispositions
    ADD CONSTRAINT dispositions_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: documents documents_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: email_messages email_messages_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT email_messages_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: email_messages email_messages_synced_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_messages
    ADD CONSTRAINT email_messages_synced_by_fkey FOREIGN KEY (synced_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: incoming_letters incoming_letters_forwarded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incoming_letters
    ADD CONSTRAINT incoming_letters_forwarded_by_fkey FOREIGN KEY (forwarded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: incoming_letters incoming_letters_forwarded_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incoming_letters
    ADD CONSTRAINT incoming_letters_forwarded_to_fkey FOREIGN KEY (forwarded_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: incoming_letters incoming_letters_letter_nature_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incoming_letters
    ADD CONSTRAINT incoming_letters_letter_nature_id_fkey FOREIGN KEY (letter_nature_id) REFERENCES public.letter_natures(id);


--
-- Name: incoming_letters incoming_letters_letter_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incoming_letters
    ADD CONSTRAINT incoming_letters_letter_type_id_fkey FOREIGN KEY (letter_type_id) REFERENCES public.letter_types(id);


--
-- Name: incoming_letters incoming_letters_registered_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.incoming_letters
    ADD CONSTRAINT incoming_letters_registered_by_fkey FOREIGN KEY (registered_by) REFERENCES public.users(id);


--
-- Name: letter_requests letter_requests_applicant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_applicant_id_fkey FOREIGN KEY (applicant_id) REFERENCES public.users(id);


--
-- Name: letter_requests letter_requests_applicant_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_applicant_unit_id_fkey FOREIGN KEY (applicant_unit_id) REFERENCES public.units(id) ON DELETE SET NULL;


--
-- Name: letter_requests letter_requests_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: letter_requests letter_requests_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: letter_requests letter_requests_letter_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_letter_type_id_fkey FOREIGN KEY (letter_type_id) REFERENCES public.letter_types(id);


--
-- Name: letter_requests letter_requests_operator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_operator_id_fkey FOREIGN KEY (operator_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: letter_requests letter_requests_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.letter_requests
    ADD CONSTRAINT letter_requests_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: notifications notifications_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: outgoing_letters outgoing_letters_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_letters
    ADD CONSTRAINT outgoing_letters_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: outgoing_letters outgoing_letters_checked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_letters
    ADD CONSTRAINT outgoing_letters_checked_by_fkey FOREIGN KEY (checked_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: outgoing_letters outgoing_letters_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_letters
    ADD CONSTRAINT outgoing_letters_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: outgoing_letters outgoing_letters_letter_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.outgoing_letters
    ADD CONSTRAINT outgoing_letters_letter_type_id_fkey FOREIGN KEY (letter_type_id) REFERENCES public.letter_types(id) ON DELETE SET NULL;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: users users_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: users users_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id) ON DELETE SET NULL;


--
-- Name: users users_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict aZdQZjk2hGAFY8SzQIhj3rXMWzztNPhRGhBLsdZqVUKEgV2bWuDhBMFT2XazY36

