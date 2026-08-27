from django.contrib import admin
from .models import (
    OfficerProfile,
    District,
    PoliceStation,
    CaseRecord,
    TransferRequest,
    AuditLog,
)

@admin.register(OfficerProfile)
class OfficerProfileAdmin(admin.ModelAdmin):
    list_display = ('name', 'badge_number', 'station_name', 'account_status', 'role_id', 'created_at')
    list_filter = ('account_status', 'role_id', 'district')
    search_fields = ('name', 'badge_number', 'email', 'phone')

@admin.register(District)
class DistrictAdminConfig(admin.ModelAdmin):
    list_display = ('name', 'district_id', 'status', 'created_at')

@admin.register(PoliceStation)
class PoliceStationAdmin(admin.ModelAdmin):
    list_display = ('station_name', 'district_name', 'zone', 'pi_in_charge')
    search_fields = ('station_name', 'district_name')

@admin.register(CaseRecord)
class CaseRecordAdmin(admin.ModelAdmin):
    list_display = ('case_number', 'title', 'module_key', 'priority', 'status', 'station_name')
    list_filter = ('priority', 'status', 'module_key')

@admin.register(TransferRequest)
class TransferRequestAdmin(admin.ModelAdmin):
    list_display = ('officer_name', 'current_station', 'requested_station', 'status', 'created_at')
    list_filter = ('status',)

@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ('actor_name', 'action', 'created_at')
    search_fields = ('actor_name', 'action')
