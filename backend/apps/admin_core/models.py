import uuid
from django.db import models


from django.contrib.auth.hashers import make_password, check_password as django_check_password


class MasterUser(models.Model):
    """
    Mapped Django ORM model for Master Admin Users stored in Supabase 'master_users' table.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=128)
    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=32, blank=True)
    is_active = models.BooleanField(default=True)
    firebase_uid = models.CharField(max_length=128, blank=True, null=True, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'master_users'
        verbose_name = 'Master Admin User'
        verbose_name_plural = 'Master Admin Users'

    def __str__(self):
        return f"MasterAdmin: {self.full_name} ({self.email})"

    def set_password(self, raw_password):
        self.password = make_password(raw_password)

    def check_password(self, raw_password):
        return django_check_password(raw_password, self.password)


class StateRegistry(models.Model):
    """
    State Registry model mapping directly to PostgreSQL 'states' table.
    """
    state_code = models.CharField(max_length=10, primary_key=True, help_text="e.g. MH, GJ, KA, DL")
    state_name = models.CharField(max_length=100, unique=True)
    schema_name = models.CharField(max_length=64, unique=True)
    police_force_title = models.CharField(max_length=255, blank=True, help_text="e.g. Gujarat State Police")
    super_admin_name = models.CharField(max_length=255, blank=True)
    super_admin_email = models.EmailField(blank=True)
    super_admin_phone = models.CharField(max_length=32, blank=True)
    super_admin_rank = models.CharField(max_length=128, blank=True, help_text="e.g. Director General of Police (DGP)")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'states'
        verbose_name = 'State Registry'
        verbose_name_plural = 'State Registries'
        ordering = ['state_name']

    def __str__(self):
        return f"{self.state_name} ({self.state_code})"

class OfficerProfile(models.Model):
    """
    Mapped Django ORM model for Police Officers, Supervisors, Station Admins, and District Admins.
    Points directly to the shared PostgreSQL table 'users_officerprofile'.
    """
    ACCOUNT_STATUS_CHOICES = (
        ('active', 'Active'),
        ('archived', 'Archived'),
        ('pending_approval', 'Pending Approval'),
        ('rejected', 'Rejected'),
    )

    uid = models.CharField(max_length=128, primary_key=True, help_text="Unique Officer Identifier / Firebase UID")
    name = models.CharField(max_length=255, blank=True)
    password = models.CharField(max_length=128, blank=True, null=True)
    badge_number = models.CharField(max_length=64, blank=True)
    designation = models.CharField(max_length=128, blank=True)
    email = models.EmailField(blank=True, unique=True)
    phone = models.CharField(max_length=32, blank=True)
    station_name = models.CharField(max_length=255, blank=True)
    station_id = models.CharField(max_length=64, blank=True, null=True)
    station_address = models.TextField(blank=True)
    station_landline = models.CharField(max_length=32, blank=True)
    govt_id = models.CharField(max_length=64, blank=True)
    photo_url = models.URLField(max_length=1024, blank=True)
    id_card_url = models.URLField(max_length=1024, blank=True, null=True)
    role_id = models.CharField(max_length=64, default='officer')
    additional_stations = models.JSONField(default=list, blank=True)
    account_status = models.CharField(max_length=32, choices=ACCOUNT_STATUS_CHOICES, default='active')
    district = models.CharField(max_length=128, blank=True, null=True)
    district_id = models.CharField(max_length=64, blank=True, null=True)
    zone = models.CharField(max_length=128, blank=True, null=True)
    station_case_view_granted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'users_officerprofile'
        verbose_name = 'Officer Profile'
        verbose_name_plural = 'Officer Profiles'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.badge_number}) - Status: {self.account_status}"

    def set_password(self, raw_password):
        self.password = make_password(raw_password)

    def check_password(self, raw_password):
        if not self.password:
            return False
        return django_check_password(raw_password, self.password)


class District(models.Model):
    """
    Mapped Django ORM model for Districts.
    Points directly to shared PostgreSQL table 'districts'.
    """
    STATUS_CHOICES = (
        ('pending_approval', 'Pending Approval'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    district_id = models.CharField(max_length=64, primary_key=True)
    name = models.CharField(max_length=128, unique=True)
    code = models.CharField(max_length=32, blank=True)
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='approved')
    approved_by_super_admin_uid = models.CharField(max_length=128, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'districts'
        verbose_name = 'District'
        verbose_name_plural = 'Districts'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.district_id})"


class PoliceStation(models.Model):
    """
    Mapped Django ORM model for Police Stations.
    Points directly to shared PostgreSQL table 'stations_policestation'.
    """
    station_id = models.CharField(max_length=64, primary_key=True)
    station_name = models.CharField(max_length=255, unique=True)
    district = models.ForeignKey(District, on_delete=models.SET_NULL, related_name='stations', null=True, blank=True)
    district_name = models.CharField(max_length=128, blank=True)
    zone = models.CharField(max_length=128, blank=True)
    address = models.TextField(blank=True)
    landline = models.CharField(max_length=32, blank=True)
    pi_in_charge = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'stations_policestation'
        verbose_name = 'Police Station'
        verbose_name_plural = 'Police Stations'
        ordering = ['station_name']

    def __str__(self):
        return f"{self.station_name} ({self.district_name})"


class CaseRecord(models.Model):
    """
    Mapped Django ORM model for Case Records.
    Points directly to shared PostgreSQL table 'cases_caserecord'.
    """
    id = models.CharField(max_length=128, primary_key=True, default=uuid.uuid4)
    module_key = models.CharField(max_length=64, db_index=True)
    title = models.CharField(max_length=255)
    case_number = models.CharField(max_length=128, db_index=True)
    description = models.TextField(blank=True)
    complainant = models.CharField(max_length=255, blank=True)
    accused = models.CharField(max_length=255, blank=True)
    location = models.CharField(max_length=255, blank=True)
    incident_date = models.DateTimeField(null=True, blank=True)
    priority = models.CharField(max_length=32, default='Low')
    status = models.CharField(max_length=32, default='Pending', db_index=True)
    assigned_officer = models.CharField(max_length=255, blank=True)
    assigned_officer_uid = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    sub_category = models.CharField(max_length=128, blank=True, null=True)
    created_by = models.CharField(max_length=128, blank=True)
    station_name = models.CharField(max_length=255, db_index=True)
    extra_fields = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'cases_caserecord'
        verbose_name = 'Case Record'
        verbose_name_plural = 'Case Records'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.module_key}] {self.case_number}: {self.title}"


class TransferRequest(models.Model):
    """
    Mapped ORM model for Officer Station Transfer Requests.
    Points directly to shared PostgreSQL table 'transfer_requests'.
    """
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    )

    id = models.CharField(max_length=128, primary_key=True, default=uuid.uuid4)
    officer_uid = models.CharField(max_length=128)
    officer_name = models.CharField(max_length=255)
    current_station = models.CharField(max_length=255)
    requested_station = models.CharField(max_length=255)
    reason = models.TextField(blank=True)
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='pending')
    processed_by = models.CharField(max_length=128, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'transfer_requests'
        verbose_name = 'Transfer Request'
        verbose_name_plural = 'Transfer Requests'
        ordering = ['-created_at']

    def __str__(self):
        return f"Transfer ({self.officer_name}): {self.current_station} -> {self.requested_station} [{self.status}]"


class AuditLog(models.Model):
    """
    Mapped ORM model for Admin and Officer system activity audit logs.
    Points directly to shared PostgreSQL table 'audit_logs'.
    """
    id = models.CharField(max_length=128, primary_key=True, default=uuid.uuid4)
    actor_uid = models.CharField(max_length=128)
    actor_name = models.CharField(max_length=255, blank=True)
    action = models.CharField(max_length=255)
    details = models.JSONField(default=dict, blank=True)
    ip_address = models.CharField(max_length=64, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'audit_logs'
        verbose_name = 'Audit Log'
        verbose_name_plural = 'Audit Logs'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.created_at}] {self.actor_name}: {self.action}"
