import logging
import uuid
from django.db import connection
from django.contrib.auth.hashers import make_password
from rest_framework import status, views, generics
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.db.models import Count, Q

logger = logging.getLogger(__name__)

from .models import (
    MasterUser,
    StateRegistry,
    OfficerProfile,
    District,
    PoliceStation,
    CaseRecord,
    TransferRequest,
    AuditLog,
)
from .serializers import (
    StateRegistrySerializer,
    CreateStateOnboardingSerializer,
    OfficerProfileSerializer,
    UpdateOfficerStatusSerializer,
    DistrictSerializer,
    PoliceStationSerializer,
    CaseRecordSerializer,
    TransferRequestSerializer,
    AuditLogSerializer,
    DashboardStatsSerializer,
)

ALL_INDIAN_STATES = [
    {'code': 'AP', 'name': 'Andhra Pradesh', 'default_force': 'Andhra Pradesh Police'},
    {'code': 'AR', 'name': 'Arunachal Pradesh', 'default_force': 'Arunachal Pradesh Police'},
    {'code': 'AS', 'name': 'Assam', 'default_force': 'Assam Police'},
    {'code': 'BR', 'name': 'Bihar', 'default_force': 'Bihar Police'},
    {'code': 'CG', 'name': 'Chhattisgarh', 'default_force': 'Chhattisgarh Police'},
    {'code': 'GA', 'name': 'Goa', 'default_force': 'Goa Police'},
    {'code': 'GJ', 'name': 'Gujarat', 'default_force': 'Gujarat State Police'},
    {'code': 'HR', 'name': 'Haryana', 'default_force': 'Haryana Police'},
    {'code': 'HP', 'name': 'Himachal Pradesh', 'default_force': 'Himachal Pradesh Police'},
    {'code': 'JH', 'name': 'Jharkhand', 'default_force': 'Jharkhand Police'},
    {'code': 'KA', 'name': 'Karnataka', 'default_force': 'Karnataka State Police'},
    {'code': 'KL', 'name': 'Kerala', 'default_force': 'Kerala Police'},
    {'code': 'MP', 'name': 'Madhya Pradesh', 'default_force': 'Madhya Pradesh Police'},
    {'code': 'MH', 'name': 'Maharashtra', 'default_force': 'Maharashtra State Police'},
    {'code': 'MN', 'name': 'Manipur', 'default_force': 'Manipur Police'},
    {'code': 'ML', 'name': 'Meghalaya', 'default_force': 'Meghalaya Police'},
    {'code': 'MZ', 'name': 'Mizoram', 'default_force': 'Mizoram Police'},
    {'code': 'NL', 'name': 'Nagaland', 'default_force': 'Nagaland Police'},
    {'code': 'OD', 'name': 'Odisha', 'default_force': 'Odisha Police'},
    {'code': 'PB', 'name': 'Punjab', 'default_force': 'Punjab Police'},
    {'code': 'RJ', 'name': 'Rajasthan', 'default_force': 'Rajasthan Police'},
    {'code': 'SK', 'name': 'Sikkim', 'default_force': 'Sikkim Police'},
    {'code': 'TN', 'name': 'Tamil Nadu', 'default_force': 'Tamil Nadu Police'},
    {'code': 'TS', 'name': 'Telangana', 'default_force': 'Telangana State Police'},
    {'code': 'TR', 'name': 'Tripura', 'default_force': 'Tripura Police'},
    {'code': 'UP', 'name': 'Uttar Pradesh', 'default_force': 'Uttar Pradesh Police'},
    {'code': 'UK', 'name': 'Uttarakhand', 'default_force': 'Uttarakhand Police'},
    {'code': 'WB', 'name': 'West Bengal', 'default_force': 'West Bengal Police'},
    {'code': 'AN', 'name': 'Andaman and Nicobar Islands', 'default_force': 'Andaman & Nicobar Police'},
    {'code': 'CH', 'name': 'Chandigarh', 'default_force': 'Chandigarh Police'},
    {'code': 'DN', 'name': 'Dadra and Nagar Haveli and Daman and Diu', 'default_force': 'Daman & Diu Police'},
    {'code': 'DL', 'name': 'Delhi', 'default_force': 'Delhi Police'},
    {'code': 'JK', 'name': 'Jammu and Kashmir', 'default_force': 'Jammu & Kashmir Police'},
    {'code': 'LA', 'name': 'Ladakh', 'default_force': 'Ladakh Police'},
    {'code': 'LD', 'name': 'Lakshadweep', 'default_force': 'Lakshadweep Police'},
    {'code': 'PY', 'name': 'Puducherry', 'default_force': 'Puducherry Police'},
]


class AvailableStatesView(views.APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        configured_codes = set(StateRegistry.objects.values_list('state_code', flat=True))
        results = []
        for item in ALL_INDIAN_STATES:
            is_added = item['code'] in configured_codes
            results.append({
                'code': item['code'],
                'name': item['name'],
                'default_force': item['default_force'],
                'is_already_added': is_added,
            })
        return Response(results, status=status.HTTP_200_OK)


class DesignationListView(views.APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        from apps.admin_core.models import Designation
        role = request.query_params.get('role') or request.query_params.get('admin_level') or request.query_params.get('allowed_for')
        qs = Designation.objects.all().order_by('rank_level', 'code')
        if role:
            r = role.lower()
            if 'state' in r:
                qs = qs.filter(is_state_admin_allowed=True)
            elif 'district' in r:
                qs = qs.filter(is_district_admin_allowed=True)
            elif 'division' in r or 'subdivision' in r:
                qs = qs.filter(is_division_admin_allowed=True)
            elif 'station' in r or 'head' in r:
                qs = qs.filter(is_station_admin_allowed=True)

        results = [
            {
                'code': d.code,
                'title': d.title,
                'display': f"{d.title} ({d.code})",
                'rank_level': d.rank_level,
                'is_state_admin_allowed': d.is_state_admin_allowed,
                'is_district_admin_allowed': d.is_district_admin_allowed,
                'is_division_admin_allowed': d.is_division_admin_allowed,
                'is_station_admin_allowed': d.is_station_admin_allowed,
            }
            for d in qs
        ]
        return Response(results, status=status.HTTP_200_OK)



class StateListCreateView(views.APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        states = StateRegistry.objects.all()
        serializer = StateRegistrySerializer(states, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = CreateStateOnboardingSerializer(data=request.data)
        if not serializer.is_valid():
            # Return first validation error message cleanly
            first_err = list(serializer.errors.values())[0]
            err_msg = first_err[0] if isinstance(first_err, list) else str(first_err)
            return Response({'error': err_msg}, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        code = data['state_code'].upper()
        name = data['state_name']
        schema_name = name.lower().replace(' ', '_')
        force_title = data.get('police_force_title') or f"{name} State Police"

        if StateRegistry.objects.filter(state_code=code).exists():
            return Response({'error': f'State {name} ({code}) is already registered!'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Create State Registry record
        state_record = StateRegistry.objects.create(
            state_code=code,
            state_name=name,
            schema_name=schema_name,
            police_force_title=force_title,
            department_logo_url=data.get('department_logo_url'),
            super_admin_name=data['super_admin_name'],
            super_admin_email=data['super_admin_email'],
            super_admin_phone=data['super_admin_phone'],
            super_admin_rank=data['super_admin_rank'],
            is_active=True
        )

        # 2. Provision new PostgreSQL Schema with all domain tables & insert Super Admin into schema
        from .tenancy import provision_state_schema_with_tables
        super_admin_uid = provision_state_schema_with_tables(schema_name, {
            'state_code': code,
            'state_name': name,
            'super_admin_name': data['super_admin_name'],
            'super_admin_email': data['super_admin_email'],
            'super_admin_phone': data['super_admin_phone'],
            'super_admin_rank': data['super_admin_rank'],
            'password': data['password'],
            'age': data.get('age'),
            'gender': data.get('gender', 'Male'),
            'photo_url': data.get('photo_url'),
            'id_card_url': data.get('id_card_url'),
        })

        # 3. Create / Update State Super Admin officer account in public schema
        officer, _ = OfficerProfile.objects.get_or_create(
            email=data['super_admin_email'],
            defaults={
                'uid': super_admin_uid,
                'name': data['super_admin_name'],
                'phone': data['super_admin_phone'],
                'badge_number': f"DGP-{code}",
                'designation': data['super_admin_rank'],
                'role_id': 'state_super_admin',
                'account_status': 'active',
                'district': f"{name} HQ",
                'station_name': f"{name} Police HQ",
                'age': data.get('age'),
                'gender': data.get('gender', 'Male'),
                'photo_url': data.get('photo_url', ''),
                'id_card_url': data.get('id_card_url', ''),
            }
        )
        officer.set_password(data['password'])
        officer.name = data['super_admin_name']
        officer.phone = data['super_admin_phone']
        officer.designation = data['super_admin_rank']
        officer.role_id = 'state_super_admin'
        officer.account_status = 'active'
        if data.get('age'):
            officer.age = data.get('age')
        if data.get('gender'):
            officer.gender = data.get('gender')
        if data.get('photo_url'):
            officer.photo_url = data.get('photo_url')
        if data.get('id_card_url'):
            officer.id_card_url = data.get('id_card_url')
        officer.save()

        # 3. Create Audit Log
        try:
            AuditLog.objects.create(
                actor_uid=request.data.get('admin_uid', 'master_admin'),
                action=f"Onboarded New State: {name} ({code}) with Super Admin {data['super_admin_name']}",
                details={'state_code': code, 'super_admin_email': data['super_admin_email']}
            )
        except Exception:
            pass

        return Response(StateRegistrySerializer(state_record).data, status=status.HTTP_201_CREATED)


class DashboardStatsView(views.APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        from .tenancy import set_tenant_schema
        schemas = ['public'] + list(StateRegistry.objects.filter(is_active=True).values_list('schema_name', flat=True))
        
        seen_officers = set()
        total_officers = 0
        pending_approvals = 0
        active_officers = 0
        archived_officers = 0
        total_stations = 0
        total_districts = 0
        total_cases = 0
        pending_transfers = 0

        for s in schemas:
            try:
                set_tenant_schema(s)
                for off in OfficerProfile.objects.all():
                    if off.uid not in seen_officers:
                        seen_officers.add(off.uid)
                        total_officers += 1
                        if off.account_status == 'pending_approval':
                            pending_approvals += 1
                        elif off.account_status == 'active':
                            active_officers += 1
                        elif off.account_status == 'archived':
                            archived_officers += 1

                total_stations += PoliceStation.objects.count()
                total_districts += District.objects.count()
                total_cases += CaseRecord.objects.count()
                pending_transfers += TransferRequest.objects.filter(status='pending').count()
            except Exception:
                pass

        set_tenant_schema('public')

        data = {
            'total_officers': total_officers,
            'pending_approvals': pending_approvals,
            'active_officers': active_officers,
            'archived_officers': archived_officers,
            'total_stations': total_stations,
            'total_districts': total_districts,
            'total_cases': total_cases,
            'pending_transfers': pending_transfers,
        }
        return Response(data, status=status.HTTP_200_OK)


class OfficerListCreateView(views.APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        from .tenancy import set_tenant_schema
        status_param = request.query_params.get('status')
        district_param = request.query_params.get('district')
        station_param = request.query_params.get('station')
        role_param = request.query_params.get('role')
        state_param = request.query_params.get('state_code')

        schemas = ['public'] + list(StateRegistry.objects.filter(is_active=True).values_list('schema_name', flat=True))
        if state_param:
            st = StateRegistry.objects.filter(state_code__iexact=state_param).first()
            if st:
                schemas = [st.schema_name]

        seen_uids = set()
        all_officers = []

        for s in schemas:
            try:
                set_tenant_schema(s)
                qs = OfficerProfile.objects.all()
                if status_param:
                    qs = qs.filter(account_status=status_param)
                if district_param:
                    qs = qs.filter(district__icontains=district_param)
                if station_param:
                    qs = qs.filter(station_name__icontains=station_param)
                if role_param:
                    qs = qs.filter(role_id=role_param)

                for off in qs:
                    if off.uid not in seen_uids:
                        seen_uids.add(off.uid)
                        all_officers.append(off)
            except Exception:
                pass

        set_tenant_schema('public')
        serializer = OfficerProfileSerializer(all_officers, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = OfficerProfileSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class OfficerDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = OfficerProfile.objects.all()
    serializer_class = OfficerProfileSerializer
    permission_classes = [AllowAny]
    lookup_field = 'uid'


class OfficerStatusApprovalView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request, uid):
        from .tenancy import set_tenant_schema
        serializer = UpdateOfficerStatusSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        new_status = serializer.validated_data['account_status']
        schemas = ['public'] + list(StateRegistry.objects.filter(is_active=True).values_list('schema_name', flat=True))

        updated_officer = None
        for s in schemas:
            try:
                set_tenant_schema(s)
                officers = OfficerProfile.objects.filter(uid=uid)
                for officer in officers:
                    officer.account_status = new_status
                    if 'role_id' in serializer.validated_data:
                        officer.role_id = serializer.validated_data['role_id']
                    officer.save()
                    updated_officer = officer
            except Exception:
                pass

        set_tenant_schema('public')

        if updated_officer:
            try:
                AuditLog.objects.create(
                    actor_uid=request.data.get('admin_uid', 'master_admin'),
                    action=f"Updated Officer ({updated_officer.name}) status to {new_status}",
                    details={'officer_uid': updated_officer.uid, 'new_status': new_status}
                )
            except Exception:
                pass

            return Response(OfficerProfileSerializer(updated_officer).data, status=status.HTTP_200_OK)

        return Response({'error': 'Officer not found across state schemas'}, status=status.HTTP_404_NOT_FOUND)


class DistrictListCreateView(generics.ListCreateAPIView):
    queryset = District.objects.all()
    serializer_class = DistrictSerializer
    permission_classes = [AllowAny]


class PoliceStationListCreateView(generics.ListCreateAPIView):
    queryset = PoliceStation.objects.all()
    serializer_class = PoliceStationSerializer
    permission_classes = [AllowAny]


class CaseRecordListView(generics.ListAPIView):
    queryset = CaseRecord.objects.all()
    serializer_class = CaseRecordSerializer
    permission_classes = [AllowAny]


class TransferRequestListCreateView(generics.ListCreateAPIView):
    queryset = TransferRequest.objects.all()
    serializer_class = TransferRequestSerializer
    permission_classes = [AllowAny]


class TransferRequestDetailView(generics.RetrieveUpdateAPIView):
    queryset = TransferRequest.objects.all()
    serializer_class = TransferRequestSerializer
    permission_classes = [AllowAny]
    lookup_field = 'id'


class AuditLogListView(generics.ListAPIView):
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
    permission_classes = [AllowAny]


class AdminLoginView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        password = request.data.get('password', '')

        if not email or not password:
            return Response({'error': 'Email and password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Check MasterUser in Supabase 'master_users' table
        master_user = MasterUser.objects.filter(email=email).first()
        if master_user:
            if not master_user.check_password(password):
                return Response({'error': 'Invalid email or password.'}, status=status.HTTP_401_UNAUTHORIZED)
            if not master_user.is_active:
                return Response({'error': 'Master Admin account is inactive.'}, status=status.HTTP_403_FORBIDDEN)

            return Response({
                'message': 'Master Admin login successful.',
                'user': {
                    'uid': str(master_user.id),
                    'email': master_user.email,
                    'name': master_user.full_name,
                    'phone': master_user.phone,
                    'role_id': 'master_admin',
                    'account_status': 'active'
                },
                'token': f'pms-jwt-token-{master_user.id}',
            }, status=status.HTTP_200_OK)

        # 2. Look up Officer Profile in PostgreSQL 'users_officerprofile' table
        officer = OfficerProfile.objects.filter(email=email).first()
        if officer:
            if officer.password and not officer.check_password(password):
                return Response({'error': 'Invalid email or password.'}, status=status.HTTP_401_UNAUTHORIZED)
            if officer.account_status != 'active':
                return Response({'error': f'Account status is {officer.account_status}. Access denied.'}, status=status.HTTP_403_FORBIDDEN)
            
            return Response({
                'message': 'Login successful.',
                'user': OfficerProfileSerializer(officer).data,
                'token': f'pms-jwt-token-{officer.uid}',
            }, status=status.HTTP_200_OK)

        return Response({'error': 'Invalid email or password.'}, status=status.HTTP_401_UNAUTHORIZED)


def _ensure_state_schema_tables(clean_schema: str):
    sql = f"""
    CREATE SCHEMA IF NOT EXISTS "{clean_schema}";
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
        age INT,
        gender VARCHAR(20),
        station_case_view_granted BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(sql)
    except Exception as e:
        logger.warning(f"Error ensuring schema tables for {clean_schema}: {e}")


class StateAdminListView(views.APIView):
    permission_classes = [AllowAny]

    def get(self, request, state_code):
        state_registry = StateRegistry.objects.filter(state_code=state_code.upper()).first()
        if not state_registry:
            return Response({'error': f'State {state_code} not found'}, status=status.HTTP_404_NOT_FOUND)

        schema_name = state_registry.schema_name
        clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()

        _ensure_state_schema_tables(clean_schema)

        sql = f"""
        SELECT uid, name, badge_number, designation, email, phone, role_id, account_status, age, gender, photo_url, id_card_url, created_at
        FROM "{clean_schema}".users_officerprofile
        ORDER BY created_at ASC;
        """
        results = []
        try:
            with connection.cursor() as cursor:
                cursor.execute(sql)
                columns = [col[0] for col in cursor.description]
                for row in cursor.fetchall():
                    row_dict = dict(zip(columns, row))
                    if row_dict.get('created_at'):
                        row_dict['created_at'] = str(row_dict['created_at'])
                    results.append(row_dict)
        except Exception as e:
            logger.warning(f"Error fetching state admins from {clean_schema}: {e}")
            try:
                officers = OfficerProfile.objects.all()
                results = [
                    {
                        'uid': o.uid,
                        'name': o.name,
                        'badge_number': o.badge_number,
                        'designation': o.designation,
                        'email': o.email,
                        'phone': o.phone,
                        'role_id': o.role_id,
                        'account_status': o.account_status,
                        'age': getattr(o, 'age', None),
                        'gender': getattr(o, 'gender', 'Male'),
                        'photo_url': getattr(o, 'photo_url', ''),
                        'id_card_url': getattr(o, 'id_card_url', ''),
                        'created_at': None
                    }
                    for o in officers if o.email.lower().endswith(f".{state_code.lower()}@pms.gov.in") or state_code.upper() in o.badge_number
                ]
            except Exception:
                results = []

        return Response(results, status=status.HTTP_200_OK)

    def post(self, request, state_code):
        state_registry = StateRegistry.objects.filter(state_code=state_code.upper()).first()
        if not state_registry:
            return Response({'error': f'State {state_code} not found'}, status=status.HTTP_404_NOT_FOUND)

        schema_name = state_registry.schema_name
        clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()

        _ensure_state_schema_tables(clean_schema)

        name = request.data.get('name', '').strip()
        email = request.data.get('email', '').strip().lower()
        phone = request.data.get('phone', '').strip()
        designation = request.data.get('designation', 'State Admin')
        password = request.data.get('password', 'StateAdmin@123')
        age = request.data.get('age')
        gender = request.data.get('gender', 'Male')
        photo_url = request.data.get('photo_url', '')
        id_card_url = request.data.get('id_card_url', '')

        if not name or not email or not phone:
            return Response({'error': 'Name, Email, and Phone number are required.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check unique email in state schema
        with connection.cursor() as cursor:
            cursor.execute(f'SELECT uid FROM "{clean_schema}".users_officerprofile WHERE email = %s;', [email])
            if cursor.fetchone():
                return Response({'error': f'An admin officer with email {email} already exists in {state_registry.state_name}!'}, status=status.HTTP_400_BAD_REQUEST)

        hashed_password = make_password(password)
        admin_uid = f"sa_{clean_schema}_{uuid.uuid4().hex[:8]}"
        badge_number = f"SA-{state_code.upper()}-{uuid.uuid4().hex[:4].upper()}"

        sql_insert = f"""
        INSERT INTO "{clean_schema}".users_officerprofile (
            uid, name, password, badge_number, designation, email, phone,
            role_id, account_status, district, station_name, age, gender, photo_url, id_card_url
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING uid, name, badge_number, designation, email, phone, role_id, account_status, age, gender, photo_url, id_card_url, created_at;
        """

        params = [
            admin_uid, name, hashed_password, badge_number, designation, email, phone,
            'state_admin', 'active', f"{state_registry.state_name} HQ", f"{state_registry.state_name} Police HQ",
            int(age) if age and str(age).isdigit() else None, gender, photo_url, id_card_url
        ]

        with connection.cursor() as cursor:
            cursor.execute(sql_insert, params)
            row = cursor.fetchone()
            columns = [col[0] for col in cursor.description]
            result = dict(zip(columns, row))
            if result.get('created_at'):
                result['created_at'] = str(result['created_at'])

        try:
            OfficerProfile.objects.update_or_create(
                email=email,
                defaults={
                    'uid': admin_uid,
                    'name': name,
                    'badge_number': badge_number,
                    'designation': designation,
                    'phone': phone,
                    'role_id': 'state_admin',
                    'account_status': 'active',
                    'district': f"{state_registry.state_name} HQ",
                    'station_name': f"{state_registry.state_name} Police HQ",
                    'age': int(age) if age and str(age).isdigit() else None,
                    'gender': gender,
                    'photo_url': photo_url,
                    'id_card_url': id_card_url
                }
            )
        except Exception as e:
            logger.warning(f"Public profile sync warning: {e}")

        return Response(result, status=status.HTTP_201_CREATED)


class StateAdminToggleStatusView(views.APIView):
    permission_classes = [AllowAny]

    def patch(self, request, state_code, uid):
        state_registry = StateRegistry.objects.filter(state_code=state_code.upper()).first()
        if not state_registry:
            return Response({'error': f'State {state_code} not found'}, status=status.HTTP_404_NOT_FOUND)

        schema_name = state_registry.schema_name
        clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()

        with connection.cursor() as cursor:
            cursor.execute(f'SELECT account_status, email FROM "{clean_schema}".users_officerprofile WHERE uid = %s;', [uid])
            row = cursor.fetchone()
            if not row:
                return Response({'error': 'Admin officer not found.'}, status=status.HTTP_404_NOT_FOUND)
            
            curr_status, email = row[0], row[1]
            new_status = 'deactivated' if curr_status == 'active' else 'active'

            cursor.execute(f'UPDATE "{clean_schema}".users_officerprofile SET account_status = %s, updated_at = CURRENT_TIMESTAMP WHERE uid = %s;', [new_status, uid])

        try:
            OfficerProfile.objects.filter(email=email).update(account_status=new_status)
        except Exception:
            pass

        return Response({
            'uid': uid,
            'email': email,
            'account_status': new_status,
            'message': f'Admin officer account has been {new_status}.'
        }, status=status.HTTP_200_OK)

