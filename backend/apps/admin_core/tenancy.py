import logging
import uuid
from django.db import connection
from django.contrib.auth.hashers import make_password

logger = logging.getLogger(__name__)


def provision_state_schema_with_tables(schema_name: str, super_admin_data: dict) -> str:
    """
    Dynamically provisions a new state tenant schema in PostgreSQL (Supabase)
    with all required domain tables (officer profiles, districts, stations, cases, transfers, audit logs).
    Inserts the State Super Admin record into the provisioned schema tables.
    """
    clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()
    if not clean_schema:
        raise ValueError("Invalid schema name")

    hashed_password = make_password(super_admin_data.get('password', 'StateAdmin@123'))
    super_admin_uid = f"sa_{clean_schema}_{uuid.uuid4().hex[:8]}"

    sql_script = f"""
    -- 1. Create Schema
    CREATE SCHEMA IF NOT EXISTS "{clean_schema}";

    -- 2. Create Officer Profile Table inside state schema
    CREATE TABLE IF NOT EXISTS "{clean_schema}".users_officerprofile (
        uid VARCHAR(128) PRIMARY KEY,
        name VARCHAR(255),
        password VARCHAR(128),
        badge_number VARCHAR(64),
        designation VARCHAR(128),
        email VARCHAR(255) UNIQUE,
        phone VARCHAR(32),
        station_name VARCHAR(255),
        station_id VARCHAR(64),
        station_address TEXT,
        station_landline VARCHAR(32),
        govt_id VARCHAR(64),
        photo_url VARCHAR(1024),
        id_card_url VARCHAR(1024),
        role_id VARCHAR(64) DEFAULT 'officer',
        additional_stations JSONB DEFAULT '[]'::jsonb,
        account_status VARCHAR(32) DEFAULT 'active',
        district VARCHAR(128),
        district_id VARCHAR(64),
        zone VARCHAR(128),
        station_case_view_granted BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );

    -- 3. Create Districts Table
    CREATE TABLE IF NOT EXISTS "{clean_schema}".districts (
        district_id VARCHAR(64) PRIMARY KEY,
        name VARCHAR(128) UNIQUE,
        code VARCHAR(32),
        status VARCHAR(32) DEFAULT 'approved',
        approved_by_super_admin_uid VARCHAR(128),
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );

    -- 4. Create Police Stations Table
    CREATE TABLE IF NOT EXISTS "{clean_schema}".stations_policestation (
        station_id VARCHAR(64) PRIMARY KEY,
        station_name VARCHAR(255) UNIQUE,
        district_id VARCHAR(64) REFERENCES "{clean_schema}".districts(district_id) ON DELETE SET NULL,
        district_name VARCHAR(128),
        zone VARCHAR(128),
        address TEXT,
        landline VARCHAR(32),
        pi_in_charge VARCHAR(255),
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );

    -- 5. Create Cases / FIRs Table
    CREATE TABLE IF NOT EXISTS "{clean_schema}".cases_caserecord (
        id VARCHAR(128) PRIMARY KEY,
        module_key VARCHAR(64),
        title VARCHAR(255),
        case_number VARCHAR(128),
        description TEXT,
        complainant VARCHAR(255),
        accused VARCHAR(255),
        location VARCHAR(255),
        incident_date TIMESTAMPTZ,
        priority VARCHAR(32) DEFAULT 'Low',
        status VARCHAR(32) DEFAULT 'Pending',
        assigned_officer VARCHAR(255),
        assigned_officer_uid VARCHAR(128),
        sub_category VARCHAR(128),
        created_by VARCHAR(128),
        station_name VARCHAR(255),
        extra_fields JSONB DEFAULT '{{}}'::jsonb,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );

    -- 6. Create Transfer Requests Table
    CREATE TABLE IF NOT EXISTS "{clean_schema}".transfer_requests (
        id VARCHAR(128) PRIMARY KEY,
        officer_uid VARCHAR(128),
        officer_name VARCHAR(255),
        current_station VARCHAR(255),
        requested_station VARCHAR(255),
        reason TEXT,
        status VARCHAR(32) DEFAULT 'pending',
        processed_by VARCHAR(128),
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );

    -- 7. Create Audit Logs Table
    CREATE TABLE IF NOT EXISTS "{clean_schema}".audit_logs (
        id VARCHAR(128) PRIMARY KEY,
        actor_uid VARCHAR(128),
        actor_name VARCHAR(255),
        action VARCHAR(255),
        details JSONB DEFAULT '{{}}'::jsonb,
        ip_address VARCHAR(64),
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );

    -- 8. Insert State Super Admin into provisioned schema
    INSERT INTO "{clean_schema}".users_officerprofile (
        uid, name, password, badge_number, designation, email, phone,
        role_id, account_status, district, station_name
    ) VALUES (
        '{super_admin_uid}',
        '{super_admin_data.get("super_admin_name", "State Super Admin")}',
        '{hashed_password}',
        'DGP-{super_admin_data.get("state_code", "ST")}',
        '{super_admin_data.get("super_admin_rank", "Director General of Police (DGP)")}',
        '{super_admin_data.get("super_admin_email")}',
        '{super_admin_data.get("super_admin_phone")}',
        'state_super_admin',
        'active',
        '{super_admin_data.get("state_name")} HQ',
        '{super_admin_data.get("state_name")} Police HQ'
    ) ON CONFLICT (email) DO UPDATE SET
        password = '{hashed_password}',
        role_id = 'state_super_admin',
        account_status = 'active';
    """

    with connection.cursor() as cursor:
        cursor.execute(sql_script)

    logger.info(f"[Tenancy] Provisioned state schema '{clean_schema}' with all domain tables and Super Admin.")
    return super_admin_uid


def set_tenant_schema(schema_name: str):
    """
    Sets PostgreSQL search_path on the active database connection.
    """
    if not schema_name:
        schema_name = 'public'
    clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()
    with connection.cursor() as cursor:
        cursor.execute(f'SET search_path TO "{clean_schema}", public;')
