from django.urls import path
from .views import (
    AdminLoginView,
    StateListCreateView,
    AvailableStatesView,
    DesignationListView,
    DashboardStatsView,
    OfficerListCreateView,
    OfficerDetailView,
    OfficerStatusApprovalView,
    DistrictListCreateView,
    PoliceStationListCreateView,
    CaseRecordListView,
    TransferRequestListCreateView,
    TransferRequestDetailView,
    AuditLogListView,
    StateAdminListView,
    StateAdminToggleStatusView,
)

urlpatterns = [
    # Primary Authentication Endpoint
    path('login/', AdminLoginView.as_view(), name='admin-login'),

    # Dynamic Police Designation Master
    path('designations/', DesignationListView.as_view(), name='admin-designation-list'),

    # State Registries & Onboarding Endpoints
    path('states/', StateListCreateView.as_view(), name='admin-state-list-create'),
    path('states/available/', AvailableStatesView.as_view(), name='admin-state-available'),
    path('states/<str:state_code>/admins/', StateAdminListView.as_view(), name='admin-state-admin-list'),
    path('states/<str:state_code>/admins/<str:uid>/toggle-status/', StateAdminToggleStatusView.as_view(), name='admin-state-admin-toggle-status'),

    # Dashboard stats & metrics
    path('stats/', DashboardStatsView.as_view(), name='admin-dashboard-stats'),

    # Officer profile & account status management
    path('officers/', OfficerListCreateView.as_view(), name='admin-officer-list'),
    path('officers/<str:uid>/', OfficerDetailView.as_view(), name='admin-officer-detail'),
    path('officers/<str:uid>/status/', OfficerStatusApprovalView.as_view(), name='admin-officer-status-update'),

    # Districts & Police Stations
    path('districts/', DistrictListCreateView.as_view(), name='admin-district-list'),
    path('stations/', PoliceStationListCreateView.as_view(), name='admin-station-list'),

    # Case overview & metrics
    path('cases/', CaseRecordListView.as_view(), name='admin-case-list'),

    # Transfer Requests management
    path('transfers/', TransferRequestListCreateView.as_view(), name='admin-transfer-list'),
    path('transfers/<str:id>/', TransferRequestDetailView.as_view(), name='admin-transfer-detail'),

    # System Audit Logs
    path('audit-logs/', AuditLogListView.as_view(), name='admin-audit-log-list'),
]
