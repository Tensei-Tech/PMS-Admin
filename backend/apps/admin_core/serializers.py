from rest_framework import serializers
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


class StateRegistrySerializer(serializers.ModelSerializer):
    class Meta:
        model = StateRegistry
        fields = '__all__'


class CreateStateOnboardingSerializer(serializers.Serializer):
    state_code = serializers.CharField(max_length=10)
    state_name = serializers.CharField(max_length=100)
    police_force_title = serializers.CharField(max_length=255, required=False, allow_blank=True)
    department_logo_url = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    super_admin_name = serializers.CharField(max_length=255)
    super_admin_email = serializers.EmailField()
    super_admin_phone = serializers.CharField(max_length=32)
    super_admin_rank = serializers.CharField(max_length=128, default='Director General of Police (DG)')
    password = serializers.CharField(max_length=128)
    age = serializers.IntegerField(required=False, allow_null=True)
    gender = serializers.CharField(max_length=20, required=False, allow_blank=True, default='Male')
    photo_url = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    id_card_url = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    def validate_super_admin_email(self, value):
        email = value.strip().lower()
        if OfficerProfile.objects.filter(email=email).exists() or MasterUser.objects.filter(email=email).exists():
            raise serializers.ValidationError(f"Email '{email}' is already registered to an existing user.")
        return email

    def validate_super_admin_phone(self, value):
        phone = value.strip()
        if OfficerProfile.objects.filter(phone=phone).exists() or MasterUser.objects.filter(phone=phone).exists():
            raise serializers.ValidationError(f"Phone number '{phone}' is already registered to another user.")
        return phone


class OfficerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = OfficerProfile
        fields = '__all__'


class UpdateOfficerStatusSerializer(serializers.Serializer):
    account_status = serializers.ChoiceField(choices=OfficerProfile.ACCOUNT_STATUS_CHOICES)
    role_id = serializers.CharField(required=False)
    station_id = serializers.CharField(required=False, allow_blank=True)
    district_id = serializers.CharField(required=False, allow_blank=True)


class DistrictSerializer(serializers.ModelSerializer):
    station_count = serializers.SerializerMethodField()

    class Meta:
        model = District
        fields = '__all__'

    def get_station_count(self, obj):
        return obj.stations.count() if hasattr(obj, 'stations') else 0


class PoliceStationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PoliceStation
        fields = '__all__'


class CaseRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = CaseRecord
        fields = '__all__'


class TransferRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = TransferRequest
        fields = '__all__'


class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = '__all__'


class DashboardStatsSerializer(serializers.Serializer):
    total_officers = serializers.IntegerField()
    pending_approvals = serializers.IntegerField()
    active_officers = serializers.IntegerField()
    archived_officers = serializers.IntegerField()
    total_stations = serializers.IntegerField()
    total_districts = serializers.IntegerField()
    total_cases = serializers.IntegerField()
    pending_transfers = serializers.IntegerField()
